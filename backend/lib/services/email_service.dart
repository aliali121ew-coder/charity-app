import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Sends transactional emails via SMTP.
///
/// Required environment variables:
///   SMTP_HOST      — e.g. smtp.gmail.com
///   SMTP_PORT      — e.g. 587 (TLS) or 465 (SSL). Defaults to 587.
///   SMTP_USERNAME  — SMTP login username / email
///   SMTP_PASSWORD  — SMTP login password / app password
///
/// Optional:
///   SMTP_FROM_EMAIL — sender address (defaults to SMTP_USERNAME)
///   SMTP_FROM_NAME  — sender display name (defaults to "تطبيق الخيرية")
class EmailService {
  static final String? _host = Platform.environment['SMTP_HOST'];
  static final String? _username = Platform.environment['SMTP_USERNAME'];
  static final String? _password = Platform.environment['SMTP_PASSWORD'];
  static final int _port =
      int.tryParse(Platform.environment['SMTP_PORT'] ?? '587') ?? 587;
  static final String _fromEmail =
      Platform.environment['SMTP_FROM_EMAIL'] ?? (_username ?? 'noreply@charity.app');
  static final String _fromName =
      Platform.environment['SMTP_FROM_NAME'] ?? 'تطبيق الخيرية';

  static bool get isConfigured =>
      _host != null && _username != null && _password != null;

  /// Sends a verification OTP to the given [email].
  static Future<void> sendVerificationCode(String email, String otp) async {
    await _send(
      to: email,
      subject: 'رمز التحقق - تطبيق الخيرية',
      html: '''
<div dir="rtl" style="font-family:Arial,sans-serif;max-width:480px;margin:auto">
  <h2 style="color:#6C63FF">تطبيق الخيرية</h2>
  <p>رمز التحقق من بريدك الإلكتروني هو:</p>
  <div style="font-size:36px;font-weight:bold;letter-spacing:10px;
              color:#6C63FF;padding:16px;background:#f4f3ff;
              border-radius:12px;text-align:center">$otp</div>
  <p style="color:#666;font-size:13px">
    الرمز صالح لمدة <strong>10 دقائق</strong> فقط.<br>
    إذا لم تطلب هذا الرمز، تجاهل هذه الرسالة.
  </p>
</div>
''',
    );
  }

  /// Sends a password-reset OTP to the given [email].
  static Future<void> sendPasswordResetCode(String email, String otp) async {
    await _send(
      to: email,
      subject: 'إعادة تعيين كلمة المرور - تطبيق الخيرية',
      html: '''
<div dir="rtl" style="font-family:Arial,sans-serif;max-width:480px;margin:auto">
  <h2 style="color:#6C63FF">استعادة كلمة المرور</h2>
  <p>رمز إعادة تعيين كلمة المرور هو:</p>
  <div style="font-size:36px;font-weight:bold;letter-spacing:10px;
              color:#6C63FF;padding:16px;background:#f4f3ff;
              border-radius:12px;text-align:center">$otp</div>
  <p style="color:#666;font-size:13px">
    الرمز صالح لمدة <strong>10 دقائق</strong> فقط.<br>
    إذا لم تطلب إعادة تعيين كلمة المرور، تجاهل هذه الرسالة.
  </p>
</div>
''',
    );
  }

  static Future<void> _send({
    required String to,
    required String subject,
    required String html,
  }) async {
    if (!isConfigured) {
      print('⚠️  EmailService: SMTP not configured — skipping email to $to');
      return;
    }
    try {
      final smtpServer = SmtpServer(
        _host!,
        port: _port,
        username: _username,
        password: _password,
        ssl: _port == 465,
        allowInsecure: false,
      );

      final message = Message()
        ..from = Address(_fromEmail, _fromName)
        ..recipients.add(to)
        ..subject = subject
        ..html = html;

      final report = await send(message, smtpServer);
      print('✉️  Email sent to $to — ${report.mail.subject}');
    } on MailerException catch (e) {
      print('✉️  Email send failed to $to: ${e.message}');
      for (final p in e.problems) {
        print('   Problem: ${p.code} ${p.msg}');
      }
    } catch (e) {
      print('✉️  Email send error to $to: $e');
    }
  }
}
