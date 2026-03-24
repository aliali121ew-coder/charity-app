import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Sends transactional emails via SMTP.
///
/// Configure via environment variables:
///   SMTP_HOST     – e.g. smtp.gmail.com  (default)
///   SMTP_PORT     – e.g. 587             (default)
///   SMTP_USER     – sender email address
///   SMTP_PASSWORD – app password (Gmail: enable 2FA → create App Password)
///   EMAIL_FROM    – display name + address, defaults to SMTP_USER
class EmailService {
  final String _host;
  final int _port;
  final String _user;
  final String _password;
  final String _from;
  final bool _ssl;

  EmailService._({
    required String host,
    required int port,
    required String user,
    required String password,
    required String from,
    required bool ssl,
  })  : _host = host,
        _port = port,
        _user = user,
        _password = password,
        _from = from,
        _ssl = ssl;

  /// Returns null if SMTP is not configured (missing SMTP_USER / SMTP_PASSWORD).
  static EmailService? fromEnv() {
    final user = Platform.environment['SMTP_USER'] ?? '';
    final password = Platform.environment['SMTP_PASSWORD'] ?? '';
    if (user.isEmpty || password.isEmpty) return null;

    final host = Platform.environment['SMTP_HOST'] ?? 'smtp.gmail.com';
    final port = int.tryParse(Platform.environment['SMTP_PORT'] ?? '587') ?? 587;
    final ssl = port == 465;
    final from = Platform.environment['EMAIL_FROM'] ?? user;

    return EmailService._(
        host: host, port: port, user: user, password: password, from: from, ssl: ssl);
  }

  SmtpServer get _smtpServer {
    if (_host == 'smtp.gmail.com') {
      return gmail(_user, _password);
    }
    return SmtpServer(
      _host,
      port: _port,
      ssl: _ssl,
      username: _user,
      password: _password,
      ignoreBadCertificate: false,
    );
  }

  /// Send OTP email. Returns true on success, false on failure.
  Future<bool> sendOtp({
    required String to,
    required String otp,
    required String purpose, // 'email_verification' | 'password_reset'
  }) async {
    final isVerification = purpose == 'email_verification';
    final subject =
        isVerification ? 'رمز تفعيل البريد الإلكتروني' : 'رمز إعادة تعيين كلمة المرور';

    final html = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; background:#f4f4f4; padding:20px; margin:0;">
  <div style="max-width:480px; margin:0 auto; background:#ffffff; border-radius:12px; padding:32px; box-shadow:0 2px 8px rgba(0,0,0,0.08);">
    <h2 style="color:#6C63FF; margin-top:0; text-align:center;">
      ${isVerification ? '✉️ تفعيل البريد الإلكتروني' : '🔑 إعادة تعيين كلمة المرور'}
    </h2>
    <p style="color:#333; font-size:15px; line-height:1.7;">
      ${isVerification ? 'شكراً لتسجيلك! استخدم الرمز التالي لتفعيل حسابك:' : 'استخدم الرمز التالي لإعادة تعيين كلمة المرور:'}
    </p>
    <div style="background:#f0eeff; border-radius:10px; padding:20px; text-align:center; margin:24px 0;">
      <span style="font-size:36px; font-weight:bold; letter-spacing:12px; color:#6C63FF;">$otp</span>
    </div>
    <p style="color:#666; font-size:13px;">
      ⏱️ صالح لمدة <strong>10 دقائق</strong> فقط.
    </p>
    <p style="color:#999; font-size:12px; margin-top:24px; border-top:1px solid #eee; padding-top:16px;">
      إذا لم تطلب هذا الرمز، تجاهل هذه الرسالة.
    </p>
  </div>
</body>
</html>
''';

    final message = Message()
      ..from = Address(_from, 'تطبيق الخير')
      ..recipients.add(to)
      ..subject = subject
      ..html = html;

    try {
      await send(message, _smtpServer);
      print('📧 Email sent to $to (purpose: $purpose)');
      return true;
    } on MailerException catch (e) {
      print('❌ Email send failed: ${e.message}');
      for (final p in e.problems) {
        print('   Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('❌ Email error: $e');
      return false;
    }
  }
}
