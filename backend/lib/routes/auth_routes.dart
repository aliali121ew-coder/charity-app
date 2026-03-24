import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:charity_backend/services/auth_service.dart';

class AuthRoutes {
  final AuthService _auth;
  late final Router router;

  AuthRoutes(this._auth) {
    router = Router()
      ..post('/login', _login)
      ..post('/logout', _logout)
      ..post('/register', _register)
      ..post('/google', _googleLogin)
      ..post('/verify-email', _verifyEmail)
      ..post('/resend-verification', _resendVerification)
      ..post('/forgot-password', _forgotPassword)
      ..post('/reset-password', _resetPassword);
  }

  // ── POST /api/auth/login ─────────────────────────────────────────────────
  Future<Response> _login(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final emailOrUsername = (body['email'] as String?)?.trim();
      final password = body['password'] as String?;

      if (emailOrUsername == null || emailOrUsername.isEmpty ||
          password == null || password.isEmpty) {
        return _err('البريد الإلكتروني وكلمة المرور مطلوبان', 400);
      }

      final result = await _auth.login(emailOrUsername, password);
      if (result == null) {
        return _err('بيانات الدخول غير صحيحة', 401);
      }

      // Check for specific error states
      if (result.containsKey('error')) {
        if (result['error'] == 'email_not_verified') {
          return Response(
            403,
            body: jsonEncode({
              'error': 'email_not_verified',
              'message': 'يرجى تأكيد بريدك الإلكتروني أولاً',
              'email': result['email'],
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
        if (result['error'] == 'account_disabled') {
          return _err('الحساب معطّل، تواصل مع الدعم', 403);
        }
        return _err('بيانات الدخول غير صحيحة', 401);
      }

      return _ok(result);
    } catch (_) {
      return _err('طلب غير صحيح', 400);
    }
  }

  // ── POST /api/auth/logout ────────────────────────────────────────────────
  Future<Response> _logout(Request req) async {
    final token = req.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token != null) _auth.logout(token);
    return _ok({'message': 'تم تسجيل الخروج بنجاح'});
  }

  // ── POST /api/auth/register ──────────────────────────────────────────────
  Future<Response> _register(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

      final name = (body['name'] as String?)?.trim() ?? '';
      final email = (body['email'] as String?)?.trim() ?? '';
      final phone = (body['phone'] as String?)?.trim() ?? '';
      final username = (body['username'] as String?)?.trim() ?? '';
      final password = body['password'] as String? ?? '';

      if (name.isEmpty || email.isEmpty || phone.isEmpty ||
          username.isEmpty || password.isEmpty) {
        return _err('جميع الحقول مطلوبة', 400);
      }
      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(email)) {
        return _err('البريد الإلكتروني غير صحيح', 400);
      }
      if (!email.toLowerCase().endsWith('@gmail.com')) {
        return _err('يُقبل بريد Gmail فقط (@gmail.com)', 400);
      }
      if (password.length < 8) {
        return _err('كلمة المرور يجب أن تكون 8 أحرف على الأقل', 400);
      }

      final result = await _auth.register(
        name: name, email: email, phone: phone,
        username: username, password: password,
      );

      if (result.containsKey('error')) {
        return _err(
          result['message'] as String? ?? 'حدث خطأ',
          result['error'] == 'server_error' ? 500 : 409,
        );
      }

      // Returns { status: 'pending_verification', email: '...', debug_code?: '...' }
      return _ok(result, statusCode: 201);
    } catch (e) {
      return _err('طلب غير صحيح', 400);
    }
  }

  // ── POST /api/auth/google ────────────────────────────────────────────────
  Future<Response> _googleLogin(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final idToken = (body['idToken'] as String?)?.trim();

      if (idToken == null || idToken.isEmpty) return _err('idToken مطلوب', 400);

      final result = await _auth.loginWithGoogle(idToken);
      if (result == null) return _err('فشل التحقق من حساب Google', 401);
      return _ok(result);
    } catch (_) {
      return _err('طلب غير صحيح', 400);
    }
  }

  // ── POST /api/auth/verify-email ──────────────────────────────────────────
  Future<Response> _verifyEmail(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();
      final code = (body['code'] as String?)?.trim();

      if (email == null || email.isEmpty || code == null || code.isEmpty) {
        return _err('البريد والرمز مطلوبان', 400);
      }

      final result = await _auth.verifyEmail(email: email, code: code);
      if (result.containsKey('error')) {
        return _err(result['message'] as String? ?? 'حدث خطأ', 400);
      }
      return _ok(result);
    } catch (_) {
      return _err('طلب غير صحيح', 400);
    }
  }

  // ── POST /api/auth/resend-verification ───────────────────────────────────
  Future<Response> _resendVerification(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();

      if (email == null || email.isEmpty) return _err('البريد الإلكتروني مطلوب', 400);

      final result = await _auth.resendVerificationCode(email);
      if (result.containsKey('error') && result['error'] == 'already_verified') {
        return _err(result['message'] as String, 409);
      }
      return _ok(result);
    } catch (_) {
      return _err('طلب غير صحيح', 400);
    }
  }

  // ── POST /api/auth/forgot-password ───────────────────────────────────────
  Future<Response> _forgotPassword(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final emailOrPhone = (body['emailOrPhone'] as String?)?.trim();

      if (emailOrPhone == null || emailOrPhone.isEmpty) {
        return _err('البريد الإلكتروني أو رقم الهاتف مطلوب', 400);
      }

      final result = await _auth.sendPasswordResetOtp(emailOrPhone);
      return _ok(result);
    } catch (_) {
      return _err('طلب غير صحيح', 400);
    }
  }

  // ── POST /api/auth/reset-password ────────────────────────────────────────
  Future<Response> _resetPassword(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final emailOrPhone = (body['emailOrPhone'] as String?)?.trim();
      final otp = (body['otp'] as String?)?.trim();
      final newPassword = body['newPassword'] as String?;

      if (emailOrPhone == null || emailOrPhone.isEmpty ||
          otp == null || otp.isEmpty ||
          newPassword == null || newPassword.isEmpty) {
        return _err('جميع الحقول مطلوبة', 400);
      }
      if (newPassword.length < 8) {
        return _err('كلمة المرور يجب أن تكون 8 أحرف على الأقل', 400);
      }

      final result = await _auth.resetPassword(
        emailOrPhone: emailOrPhone, otp: otp, newPassword: newPassword,
      );

      if (result.containsKey('error')) {
        return _err(result['message'] as String? ?? 'حدث خطأ', 400);
      }
      return _ok(result);
    } catch (_) {
      return _err('طلب غير صحيح', 400);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Response _ok(dynamic data, {int statusCode = 200}) => Response(
        statusCode,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

  Response _err(String message, int statusCode) => Response(
        statusCode,
        body: jsonEncode({'error': message}),
        headers: {'Content-Type': 'application/json'},
      );
}
