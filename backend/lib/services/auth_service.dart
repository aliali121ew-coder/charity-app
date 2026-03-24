import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import 'package:charity_backend/models/user.dart';
import 'package:charity_backend/services/db.dart';
import 'package:charity_backend/services/email_service.dart';

class _OtpRecord {
  final String code;
  final String purpose;
  final DateTime expiresAt;
  _OtpRecord({required this.code, required this.purpose, required this.expiresAt});
}

/// Full authentication service — email/password, Google OAuth, OTP reset,
/// email verification.
///
/// When [db] is null, falls back to in-memory store (development only).
class AuthService {
  final Db? _db;
  final String _jwtSecret;
  final bool _isProduction;
  final EmailService? _email;
  static const _uuid = Uuid();

  // ── In-memory fallback (development) ──────────────────────────────────────
  static final List<User> _memUsers = [];
  static final Map<String, _OtpRecord> _memOtpStore = {};
  static bool _seeded = false;

  AuthService({Db? db})
      : _db = db,
        _jwtSecret = Platform.environment['JWT_SECRET'] ??
            'dev-secret-change-in-production-!!',
        _isProduction = Platform.environment['PRODUCTION'] == 'true',
        _email = EmailService.fromEnv() {
    if (!_seeded) {
      _seeded = true;
      _memUsers.addAll([
        User(
          id: 'seed_admin_001',
          name: 'مدير النظام',
          email: 'admin@charity.org',
          username: 'admin',
          passwordHash: hashPassword('admin123'),
          role: UserRole.admin,
          isActive: true,
          emailVerified: true,
          createdAt: DateTime(2024, 1, 1),
        ),
        User(
          id: 'seed_emp_002',
          name: 'أحمد محمد',
          email: 'employee@charity.org',
          username: 'ahmed',
          passwordHash: hashPassword('emp123'),
          role: UserRole.employee,
          isActive: true,
          emailVerified: true,
          createdAt: DateTime(2024, 1, 15),
        ),
      ]);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Password — SHA-256 + random 16-byte salt
  // ─────────────────────────────────────────────────────────────────────────

  static String hashPassword(String password) {
    final salt = List.generate(16, (_) => Random.secure().nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final hash = sha256.convert(utf8.encode(salt + password)).toString();
    return '$salt:$hash';
  }

  static bool verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final hash = sha256.convert(utf8.encode(parts[0] + password)).toString();
    return hash == parts[1];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JWT
  // ─────────────────────────────────────────────────────────────────────────

  String _generateToken(String userId, String role) {
    final jwt = JWT({'userId': userId, 'role': role});
    return jwt.sign(SecretKey(_jwtSecret),
        expiresIn: const Duration(days: 7));
  }

  String? validateToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return (jwt.payload as Map<String, dynamic>)['userId']?.toString();
    } catch (_) {
      return null;
    }
  }

  void logout(String token) {
    // JWT is stateless — add to a Redis blacklist in production.
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Login — checks email_verified + is_active
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> login(
      String emailOrUsername, String password) async {
    return _db != null
        ? await _loginDb(emailOrUsername, password)
        : _loginMemory(emailOrUsername, password);
  }

  Future<Map<String, dynamic>?> _loginDb(
      String emailOrUsername, String password) async {
    try {
      final rs = await _db!.conn.execute(
        Sql.named(
            'SELECT * FROM users WHERE (LOWER(email)=@q OR LOWER(username)=@q) LIMIT 1'),
        parameters: {'q': emailOrUsername.toLowerCase()},
      );
      if (rs.isEmpty) return null;
      final row = rs.first.toColumnMap();
      final user = User.fromRow(row);

      if (user.passwordHash == null) return null;
      if (!verifyPassword(password, user.passwordHash!)) return null;

      // Block unverified accounts
      if (user.emailVerified != true) {
        return {'error': 'email_not_verified', 'email': user.email};
      }
      if (user.isActive != true) {
        return {'error': 'account_disabled'};
      }

      return _ok(user);
    } catch (e) {
      print('Login DB error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _loginMemory(
      String emailOrUsername, String password) {
    final q = emailOrUsername.toLowerCase();
    final user = _memUsers.cast<User?>().firstWhere(
          (u) =>
              u!.email.toLowerCase() == q ||
              u.username?.toLowerCase() == q,
          orElse: () => null,
        );
    if (user == null || user.passwordHash == null) return null;
    if (!verifyPassword(password, user.passwordHash!)) return null;
    if (user.emailVerified != true) {
      return {'error': 'email_not_verified', 'email': user.email};
    }
    if (user.isActive != true) {
      return {'error': 'account_disabled'};
    }
    return _ok(user);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Register — creates user as pending_verification
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    return _db != null
        ? await _registerDb(
            name: name, email: email, phone: phone,
            username: username, password: password)
        : _registerMemory(
            name: name, email: email, phone: phone,
            username: username, password: password);
  }

  Future<Map<String, dynamic>> _registerDb({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    try {
      final emailChk = await _db!.conn.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(email)=@e LIMIT 1'),
        parameters: {'e': email.toLowerCase()},
      );
      if (emailChk.isNotEmpty) {
        return {'error': 'email_exists', 'message': 'البريد الإلكتروني مستخدم بالفعل'};
      }

      final unameChk = await _db!.conn.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(username)=@u LIMIT 1'),
        parameters: {'u': username.toLowerCase()},
      );
      if (unameChk.isNotEmpty) {
        return {'error': 'username_exists', 'message': 'اسم المستخدم محجوز'};
      }

      final id = _uuid.v4();
      await _db!.conn.execute(
        Sql.named('''
INSERT INTO users (id,name,email,phone,username,password_hash,role,is_active,email_verified,created_at)
VALUES (@id,@name,@email,@phone,@username,@hash,'beneficiary',false,false,NOW())
'''),
        parameters: {
          'id': id, 'name': name, 'email': email.toLowerCase(),
          'phone': phone, 'username': username.toLowerCase(),
          'hash': hashPassword(password),
        },
      );

      // Send verification code
      final codeResult = await _sendVerificationCode(email.toLowerCase());
      return {
        'status': 'pending_verification',
        'email': email.toLowerCase(),
        if (!_isProduction && codeResult['debug_code'] != null)
          'debug_code': codeResult['debug_code'],
      };
    } on PgException catch (e) {
      if (e.message.contains('email')) {
        return {'error': 'email_exists', 'message': 'البريد الإلكتروني مستخدم بالفعل'};
      }
      if (e.message.contains('username')) {
        return {'error': 'username_exists', 'message': 'اسم المستخدم محجوز'};
      }
      print('Register PG error: $e');
      return {'error': 'server_error', 'message': 'حدث خطأ في الخادم'};
    } catch (e) {
      print('Register error: $e');
      return {'error': 'server_error', 'message': 'حدث خطأ في الخادم'};
    }
  }

  Map<String, dynamic> _registerMemory({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
  }) {
    if (_memUsers.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return {'error': 'email_exists', 'message': 'البريد الإلكتروني مستخدم بالفعل'};
    }
    if (_memUsers.any((u) => u.username?.toLowerCase() == username.toLowerCase())) {
      return {'error': 'username_exists', 'message': 'اسم المستخدم محجوز'};
    }
    final user = User(
      id: _uuid.v4(), name: name, email: email, phone: phone,
      username: username, passwordHash: hashPassword(password),
      role: UserRole.beneficiary, isActive: false, emailVerified: false,
      createdAt: DateTime.now(),
    );
    _memUsers.add(user);

    final otp = _generateOtp();
    final exp = DateTime.now().toUtc().add(const Duration(minutes: 10));
    _memOtpStore['verify:${email.toLowerCase()}'] =
        _OtpRecord(code: otp, purpose: 'email_verification', expiresAt: exp);

    print('\n📧 Verification OTP [${email}] → $otp\n');

    return {
      'status': 'pending_verification',
      'email': email.toLowerCase(),
      if (!_isProduction) 'debug_code': otp,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Email Verification
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final key = email.toLowerCase().trim();
    return _db != null
        ? await _verifyEmailDb(key, code)
        : _verifyEmailMemory(key, code);
  }

  Future<Map<String, dynamic>> _verifyEmailDb(String email, String code) async {
    try {
      final rs = await _db!.conn.execute(
        Sql.named('''
SELECT id FROM otp_codes
WHERE email_or_phone=@ep AND code=@code AND purpose='email_verification'
  AND used=false AND expires_at>NOW()
ORDER BY created_at DESC LIMIT 1
'''),
        parameters: {'ep': email, 'code': code},
      );

      if (rs.isEmpty) {
        return {'error': 'invalid_code', 'message': 'الرمز غير صحيح أو انتهت صلاحيته'};
      }

      final otpId = rs.first.toColumnMap()['id'] as String;
      await _db!.conn.execute(
        Sql.named('UPDATE otp_codes SET used=true WHERE id=@id'),
        parameters: {'id': otpId},
      );
      await _db!.conn.execute(
        Sql.named('UPDATE users SET is_active=true, email_verified=true WHERE LOWER(email)=@e'),
        parameters: {'e': email},
      );

      // Fetch user and return token
      final userRs = await _db!.conn.execute(
        Sql.named('SELECT * FROM users WHERE LOWER(email)=@e LIMIT 1'),
        parameters: {'e': email},
      );
      if (userRs.isEmpty) return {'error': 'user_not_found'};
      return _ok(User.fromRow(userRs.first.toColumnMap()));
    } catch (e) {
      print('VerifyEmail DB error: $e');
      return {'error': 'server_error', 'message': 'حدث خطأ في الخادم'};
    }
  }

  Map<String, dynamic> _verifyEmailMemory(String email, String code) {
    final rec = _memOtpStore['verify:$email'];
    if (rec == null || rec.code != code || rec.purpose != 'email_verification' ||
        rec.expiresAt.isBefore(DateTime.now())) {
      return {'error': 'invalid_code', 'message': 'الرمز غير صحيح أو انتهت صلاحيته'};
    }
    _memOtpStore.remove('verify:$email');
    final idx = _memUsers.indexWhere((u) => u.email.toLowerCase() == email);
    if (idx == -1) return {'error': 'user_not_found'};
    _memUsers[idx] = _memUsers[idx].copyWith(isActive: true, emailVerified: true);
    return _ok(_memUsers[idx]);
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    final key = email.toLowerCase().trim();

    // Check user exists and not yet verified
    bool userExists = false;
    bool alreadyVerified = false;

    if (_db != null) {
      try {
        final rs = await _db!.conn.execute(
          Sql.named('SELECT email_verified FROM users WHERE LOWER(email)=@e LIMIT 1'),
          parameters: {'e': key},
        );
        if (rs.isNotEmpty) {
          userExists = true;
          alreadyVerified = rs.first.toColumnMap()['email_verified'] == true;
        }
      } catch (_) {}
    } else {
      final user = _memUsers.cast<User?>()
          .firstWhere((u) => u!.email.toLowerCase() == key, orElse: () => null);
      if (user != null) {
        userExists = true;
        alreadyVerified = user.emailVerified == true;
      }
    }

    if (!userExists) return {'message': 'إذا كان البريد موجوداً، ستستلم الرمز قريباً'};
    if (alreadyVerified) return {'error': 'already_verified', 'message': 'البريد محقق بالفعل'};

    final result = await _sendVerificationCode(key);
    return {'message': 'تم إرسال رمز التحقق', ...result};
  }

  Future<Map<String, dynamic>> _sendVerificationCode(String email) async {
    final otp = _generateOtp();
    final exp = DateTime.now().toUtc().add(const Duration(minutes: 10));

    if (_db != null) {
      try {
        // Invalidate old codes
        await _db!.conn.execute(
          Sql.named('''
UPDATE otp_codes SET used=true
WHERE email_or_phone=@e AND purpose='email_verification' AND used=false
'''),
          parameters: {'e': email},
        );
        await _db!.conn.execute(
          Sql.named('''
INSERT INTO otp_codes (id,email_or_phone,code,purpose,expires_at,used,created_at)
VALUES (@id,@ep,@code,'email_verification',@exp,false,NOW())
'''),
          parameters: {'id': _uuid.v4(), 'ep': email, 'code': otp, 'exp': exp},
        );
      } catch (e) {
        print('Send verification code error: $e');
      }
    } else {
      _memOtpStore['verify:$email'] =
          _OtpRecord(code: otp, purpose: 'email_verification', expiresAt: exp);
    }

    // ── Send real email if SMTP is configured ─────────────────────────────
    bool emailSent = false;
    if (_email != null) {
      emailSent = await _email!.sendOtp(
          to: email, otp: otp, purpose: 'email_verification');
    }
    // ───────────────────────────────────────────────────────────────────────

    print('\n📧 Verification OTP [$email] → $otp (expires: $exp, sent: $emailSent)\n');

    return {
      'message': 'تم إرسال رمز التحقق',
      // Always return debug_code in non-production OR when email failed
      if (!_isProduction || !emailSent) 'debug_code': otp,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Google OAuth — auto-verified (Google already verified the email)
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> loginWithGoogle(String idToken) async {
    final gData = await _verifyGoogleToken(idToken);
    if (gData == null) return null;

    final googleId = gData['sub'] as String;
    final email = (gData['email'] as String? ?? '').toLowerCase();
    final name = gData['name'] as String? ??
        gData['given_name'] as String? ??
        email.split('@')[0];
    final emailVerified = gData['email_verified'] == true ||
        gData['email_verified'] == 'true';

    return _db != null
        ? await _googleLoginDb(
            googleId: googleId, email: email, name: name,
            emailVerified: emailVerified)
        : _googleLoginMemory(
            googleId: googleId, email: email, name: name);
  }

  Future<Map<String, dynamic>?> _verifyGoogleToken(String idToken) async {
    try {
      final resp = await http.get(Uri.parse(
          'https://oauth2.googleapis.com/tokeninfo?id_token=$idToken'));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final clientId = Platform.environment['GOOGLE_CLIENT_ID'] ?? '';
      if (clientId.isNotEmpty && data['aud'] != clientId) {
        print('Google aud mismatch: ${data['aud']} vs $clientId');
        return null;
      }
      return data;
    } catch (e) {
      print('Google verify error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _googleLoginDb({
    required String googleId,
    required String email,
    required String name,
    required bool emailVerified,
  }) async {
    try {
      // 1. Find by google_id
      var rs = await _db!.conn.execute(
        Sql.named('SELECT * FROM users WHERE google_id=@g LIMIT 1'),
        parameters: {'g': googleId},
      );

      if (rs.isEmpty) {
        // 2. Find by email → link Google ID
        rs = await _db!.conn.execute(
          Sql.named('SELECT * FROM users WHERE LOWER(email)=@e LIMIT 1'),
          parameters: {'e': email},
        );

        if (rs.isNotEmpty) {
          await _db!.conn.execute(
            Sql.named('UPDATE users SET google_id=@g, is_active=true, email_verified=true WHERE LOWER(email)=@e'),
            parameters: {'g': googleId, 'e': email},
          );
        } else {
          // 3. Create new account — auto-activated
          final id = _uuid.v4();
          await _db!.conn.execute(
            Sql.named('''
INSERT INTO users (id,name,email,google_id,role,is_active,email_verified,created_at)
VALUES (@id,@name,@email,@g,'beneficiary',true,true,NOW())
'''),
            parameters: {'id': id, 'name': name, 'email': email, 'g': googleId},
          );
          return _ok(User(
            id: id, name: name, email: email, googleId: googleId,
            role: UserRole.beneficiary, isActive: true, emailVerified: true,
            createdAt: DateTime.now(),
          ));
        }

        rs = await _db!.conn.execute(
          Sql.named('SELECT * FROM users WHERE LOWER(email)=@e LIMIT 1'),
          parameters: {'e': email},
        );
      }

      if (rs.isEmpty) return null;
      final user = User.fromRow(rs.first.toColumnMap());
      if (user.isActive != true) {
        // Reactivate if was pending (linked Google account)
        await _db!.conn.execute(
          Sql.named('UPDATE users SET is_active=true, email_verified=true WHERE id=@id'),
          parameters: {'id': user.id},
        );
        return _ok(user.copyWith(isActive: true, emailVerified: true));
      }
      return _ok(user);
    } catch (e) {
      print('Google login DB error: $e');
      return null;
    }
  }

  Map<String, dynamic> _googleLoginMemory({
    required String googleId,
    required String email,
    required String name,
  }) {
    var user = _memUsers.cast<User?>().firstWhere(
          (u) => u!.googleId == googleId || u.email.toLowerCase() == email,
          orElse: () => null,
        );
    if (user == null) {
      user = User(
        id: _uuid.v4(), name: name, email: email, googleId: googleId,
        role: UserRole.beneficiary, isActive: true, emailVerified: true,
        createdAt: DateTime.now(),
      );
      _memUsers.add(user);
    } else {
      final idx = _memUsers.indexOf(user);
      _memUsers[idx] = user.copyWith(
          googleId: googleId, isActive: true, emailVerified: true);
      user = _memUsers[idx];
    }
    return _ok(user);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTP — Forgot Password
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendPasswordResetOtp(
      String emailOrPhone) async {
    final key = emailOrPhone.toLowerCase().trim();

    bool exists = false;
    if (_db != null) {
      try {
        final rs = await _db!.conn.execute(
          Sql.named('SELECT id FROM users WHERE LOWER(email)=@q OR phone=@q LIMIT 1'),
          parameters: {'q': key},
        );
        exists = rs.isNotEmpty;
      } catch (_) {}
    } else {
      exists = _memUsers.any((u) =>
          u.email.toLowerCase() == key || u.phone == emailOrPhone.trim());
    }

    final result = <String, dynamic>{
      'message': 'إذا كانت البيانات صحيحة، ستستلم رمز التحقق قريباً'
    };
    if (!exists) return result;

    final otp = _generateOtp();
    final exp = DateTime.now().toUtc().add(const Duration(minutes: 10));

    if (_db != null) {
      try {
        await _db!.conn.execute(
          Sql.named('''
INSERT INTO otp_codes (id,email_or_phone,code,purpose,expires_at,used,created_at)
VALUES (@id,@ep,@code,'password_reset',@exp,false,NOW())
'''),
          parameters: {'id': _uuid.v4(), 'ep': key, 'code': otp, 'exp': exp},
        );
      } catch (e) {
        print('OTP insert error: $e');
      }
    } else {
      _memOtpStore[key] = _OtpRecord(
          code: otp, purpose: 'password_reset', expiresAt: exp);
    }

    bool emailSent = false;
    if (_email != null && key.contains('@')) {
      emailSent = await _email!.sendOtp(
          to: key, otp: otp, purpose: 'password_reset');
    }

    print('\n🔑 Reset OTP [$emailOrPhone] → $otp (expires: $exp, sent: $emailSent)\n');
    if (!_isProduction || !emailSent) result['debug_otp'] = otp;
    return result;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    final key = emailOrPhone.toLowerCase().trim();
    bool valid = false;
    String? otpId;

    if (_db != null) {
      try {
        final rs = await _db!.conn.execute(
          Sql.named('''
SELECT id FROM otp_codes
WHERE email_or_phone=@ep AND code=@code AND purpose='password_reset'
  AND used=false AND expires_at>NOW()
ORDER BY created_at DESC LIMIT 1
'''),
          parameters: {'ep': key, 'code': otp},
        );
        if (rs.isNotEmpty) {
          valid = true;
          otpId = rs.first.toColumnMap()['id'] as String;
        }
      } catch (_) {}
    } else {
      final rec = _memOtpStore[key];
      if (rec != null && rec.code == otp && rec.purpose == 'password_reset' &&
          rec.expiresAt.isAfter(DateTime.now())) {
        valid = true;
      }
    }

    if (!valid) {
      return {'error': 'invalid_otp', 'message': 'الرمز غير صحيح أو انتهت صلاحيته'};
    }

    final newHash = hashPassword(newPassword);

    if (_db != null) {
      if (otpId != null) {
        await _db!.conn.execute(
          Sql.named('UPDATE otp_codes SET used=true WHERE id=@id'),
          parameters: {'id': otpId},
        );
      }
      await _db!.conn.execute(
        Sql.named('UPDATE users SET password_hash=@h WHERE LOWER(email)=@q OR phone=@q'),
        parameters: {'h': newHash, 'q': key},
      );
    } else {
      _memOtpStore.remove(key);
      final idx = _memUsers.indexWhere((u) =>
          u.email.toLowerCase() == key || u.phone == emailOrPhone.trim());
      if (idx != -1) {
        _memUsers[idx] = _memUsers[idx].copyWith(passwordHash: newHash);
      }
    }

    return {'message': 'تم تعيين كلمة المرور الجديدة بنجاح'};
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Seeds default admin + employee into Postgres if they don't exist yet.
  Future<void> seedDb() async {
    if (_db == null) return;
    try {
      final seeds = [
        (
          id: 'seed_admin_001',
          name: 'مدير النظام',
          email: 'admin@charity.org',
          username: 'admin',
          password: 'admin123',
          role: 'admin',
        ),
        (
          id: 'seed_emp_002',
          name: 'أحمد محمد',
          email: 'employee@charity.org',
          username: 'ahmed',
          password: 'emp123',
          role: 'employee',
        ),
      ];
      for (final s in seeds) {
        final exists = await _db!.conn.execute(
          Sql.named('SELECT id FROM users WHERE id=@id LIMIT 1'),
          parameters: {'id': s.id},
        );
        if (exists.isEmpty) {
          await _db!.conn.execute(
            Sql.named('''
INSERT INTO users (id,name,email,username,password_hash,role,is_active,email_verified,created_at)
VALUES (@id,@name,@email,@uname,@hash,@role,true,true,NOW())
'''),
            parameters: {
              'id': s.id,
              'name': s.name,
              'email': s.email,
              'uname': s.username,
              'hash': hashPassword(s.password),
              'role': s.role,
            },
          );
          print('✅ Seeded user: ${s.email}');
        } else {
          // Ensure existing seed users are always active + verified
          await _db!.conn.execute(
            Sql.named('UPDATE users SET is_active=true, email_verified=true WHERE id=@id'),
            parameters: {'id': s.id},
          );
        }
      }
    } catch (e) {
      print('Seed error: $e');
    }
  }

  String _generateOtp() =>
      (100000 + Random.secure().nextInt(900000)).toString();

  Map<String, dynamic> _ok(User user) => {
        'token': _generateToken(user.id, user.role.name),
        'user': user.toPublicJson(),
        'expiresIn': 604800,
      };
}
