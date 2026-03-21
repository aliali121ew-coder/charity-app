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

class _OtpRecord {
  final String code;
  final DateTime expiresAt;
  _OtpRecord({required this.code, required this.expiresAt});
}

/// Full authentication service — email/password, Google OAuth, OTP reset.
///
/// When [db] is null, falls back to in-memory store (development only).
class AuthService {
  final Db? _db;
  final String _jwtSecret;
  final bool _isProduction;
  static const _uuid = Uuid();

  // ── In-memory fallback (development) ─────────────────────────────────────
  static final List<User> _memUsers = [];
  static final Map<String, _OtpRecord> _memOtpStore = {};
  static bool _seeded = false;

  AuthService({Db? db})
      : _db = db,
        _jwtSecret = Platform.environment['JWT_SECRET'] ??
            'dev-secret-change-in-production-!!',
        _isProduction = Platform.environment['PRODUCTION'] == 'true' {
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
          createdAt: DateTime(2024, 1, 1),
        ),
        User(
          id: 'seed_emp_002',
          name: 'أحمد محمد',
          email: 'employee@charity.org',
          username: 'ahmed',
          passwordHash: hashPassword('emp123'),
          role: UserRole.employee,
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

  /// Returns userId when token is valid, null otherwise.
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
  // Login
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
      // ignore: unnecessary_non_null_assertion
      final rs = await _db!.conn.execute(
        Sql.named(
            'SELECT * FROM users WHERE (LOWER(email)=@q OR LOWER(username)=@q) AND is_active=true LIMIT 1'),
        parameters: {'q': emailOrUsername.toLowerCase()},
      );
      if (rs.isEmpty) return null;
      final user = User.fromRow(rs.first.toColumnMap());
      if (user.passwordHash == null) return null;
      if (!verifyPassword(password, user.passwordHash!)) return null;
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
    return _ok(user);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Register
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
            name: name,
            email: email,
            phone: phone,
            username: username,
            password: password)
        : _registerMemory(
            name: name,
            email: email,
            phone: phone,
            username: username,
            password: password);
  }

  Future<Map<String, dynamic>> _registerDb({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    try {
      // ignore: unnecessary_non_null_assertion
      final emailChk = await _db!.conn.execute(
        Sql.named('SELECT id FROM users WHERE LOWER(email)=@e LIMIT 1'),
        parameters: {'e': email.toLowerCase()},
      );
      if (emailChk.isNotEmpty) {
        return {
          'error': 'email_exists',
          'message': 'البريد الإلكتروني مستخدم بالفعل'
        };
      }

      // ignore: unnecessary_non_null_assertion
      final unameChk = await _db!.conn.execute(
        Sql.named(
            'SELECT id FROM users WHERE LOWER(username)=@u LIMIT 1'),
        parameters: {'u': username.toLowerCase()},
      );
      if (unameChk.isNotEmpty) {
        return {'error': 'username_exists', 'message': 'اسم المستخدم محجوز'};
      }

      final id = _uuid.v4();
      // ignore: unnecessary_non_null_assertion
      await _db!.conn.execute(
        Sql.named('''
INSERT INTO users (id,name,email,phone,username,password_hash,role,is_active,created_at)
VALUES (@id,@name,@email,@phone,@username,@hash,'beneficiary',true,NOW())
'''),
        parameters: {
          'id': id,
          'name': name,
          'email': email.toLowerCase(),
          'phone': phone,
          'username': username.toLowerCase(),
          'hash': hashPassword(password),
        },
      );
      return _ok(User(
        id: id,
        name: name,
        email: email,
        phone: phone,
        username: username,
        role: UserRole.beneficiary,
        createdAt: DateTime.now(),
      ));
    } on PgException catch (e) {
      if (e.message.contains('email')) {
        return {
          'error': 'email_exists',
          'message': 'البريد الإلكتروني مستخدم بالفعل'
        };
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
      return {
        'error': 'email_exists',
        'message': 'البريد الإلكتروني مستخدم بالفعل'
      };
    }
    if (_memUsers
        .any((u) => u.username?.toLowerCase() == username.toLowerCase())) {
      return {'error': 'username_exists', 'message': 'اسم المستخدم محجوز'};
    }
    final user = User(
      id: _uuid.v4(),
      name: name,
      email: email,
      phone: phone,
      username: username,
      passwordHash: hashPassword(password),
      role: UserRole.beneficiary,
      createdAt: DateTime.now(),
    );
    _memUsers.add(user);
    return _ok(user);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Google OAuth
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> loginWithGoogle(String idToken) async {
    final gData = await _verifyGoogleToken(idToken);
    if (gData == null) return null;

    final googleId = gData['sub'] as String;
    final email =
        (gData['email'] as String? ?? '').toLowerCase();
    final name = gData['name'] as String? ??
        gData['given_name'] as String? ??
        email.split('@')[0];

    return _db != null
        ? await _googleLoginDb(
            googleId: googleId, email: email, name: name)
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
  }) async {
    try {
      // 1. Find by google_id
      // ignore: unnecessary_non_null_assertion
      var rs = await _db!.conn.execute(
        Sql.named(
            'SELECT * FROM users WHERE google_id=@g AND is_active=true LIMIT 1'),
        parameters: {'g': googleId},
      );

      if (rs.isEmpty) {
        // 2. Find by email → link Google ID
        // ignore: unnecessary_non_null_assertion
        rs = await _db!.conn.execute(
          Sql.named(
              'SELECT * FROM users WHERE LOWER(email)=@e AND is_active=true LIMIT 1'),
          parameters: {'e': email},
        );

        if (rs.isNotEmpty) {
          // ignore: unnecessary_non_null_assertion
          await _db!.conn.execute(
            Sql.named(
                'UPDATE users SET google_id=@g WHERE LOWER(email)=@e'),
            parameters: {'g': googleId, 'e': email},
          );
        } else {
          // 3. Create new Google account
          final id = _uuid.v4();
          // ignore: unnecessary_non_null_assertion
          await _db!.conn.execute(
            Sql.named('''
INSERT INTO users (id,name,email,google_id,role,is_active,created_at)
VALUES (@id,@name,@email,@g,'beneficiary',true,NOW())
'''),
            parameters: {
              'id': id,
              'name': name,
              'email': email,
              'g': googleId,
            },
          );
          return _ok(User(
            id: id,
            name: name,
            email: email,
            googleId: googleId,
            role: UserRole.beneficiary,
            createdAt: DateTime.now(),
          ));
        }

        // Re-fetch after update
        // ignore: unnecessary_non_null_assertion
        rs = await _db!.conn.execute(
          Sql.named(
              'SELECT * FROM users WHERE LOWER(email)=@e LIMIT 1'),
          parameters: {'e': email},
        );
      }

      if (rs.isEmpty) return null;
      return _ok(User.fromRow(rs.first.toColumnMap()));
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
        id: _uuid.v4(),
        name: name,
        email: email,
        googleId: googleId,
        role: UserRole.beneficiary,
        createdAt: DateTime.now(),
      );
      _memUsers.add(user);
    } else if (user.googleId == null) {
      final idx = _memUsers.indexOf(user);
      _memUsers[idx] = user.copyWith(googleId: googleId);
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

    // Check user exists (silently — don't reveal)
    bool exists = false;
    if (_db != null) {
      try {
        // ignore: unnecessary_non_null_assertion
        final rs = await _db!.conn.execute(
          Sql.named(
              'SELECT id FROM users WHERE LOWER(email)=@q OR phone=@q LIMIT 1'),
          parameters: {'q': key},
        );
        exists = rs.isNotEmpty;
      } catch (_) {}
    } else {
      exists = _memUsers.any((u) =>
          u.email.toLowerCase() == key ||
          u.phone == emailOrPhone.trim());
    }

    final result = <String, dynamic>{
      'message': 'إذا كانت البيانات صحيحة، ستستلم رمز التحقق قريباً'
    };
    if (!exists) return result;

    final otp =
        (100000 + Random.secure().nextInt(900000)).toString();
    final exp = DateTime.now().toUtc().add(const Duration(minutes: 10));

    if (_db != null) {
      try {
        // ignore: unnecessary_non_null_assertion
        await _db!.conn.execute(
          Sql.named('''
INSERT INTO otp_codes (id,email_or_phone,code,expires_at,used,created_at)
VALUES (@id,@ep,@code,@exp,false,NOW())
'''),
          parameters: {
            'id': _uuid.v4(),
            'ep': key,
            'code': otp,
            'exp': exp,
          },
        );
      } catch (e) {
        print('OTP insert error: $e');
      }
    } else {
      _memOtpStore[key] = _OtpRecord(code: otp, expiresAt: exp);
    }

    // ── Production: plug in SendGrid / Twilio here ────────────────────────
    // await EmailService.sendOtp(to: emailOrPhone, code: otp);
    // ─────────────────────────────────────────────────────────────────────

    print('\n🔑 OTP [$emailOrPhone] → $otp (expires: $exp)\n');

    if (!_isProduction) result['debug_otp'] = otp;
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
        // ignore: unnecessary_non_null_assertion
        final rs = await _db!.conn.execute(
          Sql.named('''
SELECT id FROM otp_codes
WHERE email_or_phone=@ep AND code=@code AND used=false AND expires_at>NOW()
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
      if (rec != null &&
          rec.code == otp &&
          rec.expiresAt.isAfter(DateTime.now())) {
        valid = true;
      }
    }

    if (!valid) {
      return {
        'error': 'invalid_otp',
        'message': 'الرمز غير صحيح أو انتهت صلاحيته'
      };
    }

    final newHash = hashPassword(newPassword);

    if (_db != null) {
      if (otpId != null) {
        // ignore: unnecessary_non_null_assertion
        await _db!.conn.execute(
          Sql.named('UPDATE otp_codes SET used=true WHERE id=@id'),
          parameters: {'id': otpId},
        );
      }
      // ignore: unnecessary_non_null_assertion
      await _db!.conn.execute(
        Sql.named(
            'UPDATE users SET password_hash=@h WHERE LOWER(email)=@q OR phone=@q'),
        parameters: {'h': newHash, 'q': key},
      );
    } else {
      _memOtpStore.remove(key);
      final idx = _memUsers.indexWhere((u) =>
          u.email.toLowerCase() == key ||
          u.phone == emailOrPhone.trim());
      if (idx != -1) {
        _memUsers[idx] = _memUsers[idx].copyWith(passwordHash: newHash);
      }
    }

    return {'message': 'تم تعيين كلمة المرور الجديدة بنجاح'};
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _ok(User user) => {
        'token': _generateToken(user.id, user.role.name),
        'user': user.toPublicJson(),
        'expiresIn': 604800, // 7 days
      };
}
