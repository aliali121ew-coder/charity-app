import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

/// Sends OTP emails.
/// Priority: Gmail SMTP → Brevo API → Resend API
///
/// Gmail SMTP (recommended):
///   SMTP_USER     = your Gmail address
///   SMTP_PASSWORD = 16-char App Password from Google Account → Security → App passwords
///
/// Brevo API:
///   BREVO_API_KEY = xsmtpsib-...
///   EMAIL_FROM    = verified sender email
class EmailService {
  final _Config _cfg;
  EmailService._(this._cfg);

  static EmailService? fromEnv() {
    final smtpUser = Platform.environment['SMTP_USER'] ?? '';
    final smtpPass = Platform.environment['SMTP_PASSWORD'] ?? '';
    final brevo    = Platform.environment['BREVO_API_KEY'] ?? '';
    final resend   = Platform.environment['RESEND_API_KEY'] ?? '';
    final from     = Platform.environment['EMAIL_FROM'] ?? smtpUser;

    if (smtpUser.isNotEmpty && smtpPass.isNotEmpty) {
      print('📧 EmailService: Gmail SMTP → $smtpUser');
      return EmailService._(_GmailConfig(user: smtpUser, password: smtpPass, from: from));
    }
    if (brevo.isNotEmpty) {
      print('📧 EmailService: Brevo API → $from');
      return EmailService._(_BrevoConfig(apiKey: brevo, from: from));
    }
    if (resend.isNotEmpty && resend.startsWith('re_')) {
      final f = from.isEmpty ? 'onboarding@resend.dev' : from;
      print('📧 EmailService: Resend API → $f');
      return EmailService._(_ResendConfig(apiKey: resend, from: f));
    }
    print('⚠️  EmailService: no provider configured (SMTP_USER/SMTP_PASSWORD or BREVO_API_KEY or RESEND_API_KEY missing)');
    return null;
  }

  Future<bool> sendOtp({required String to, required String otp, required String purpose}) async {
    final isVerify = purpose == 'email_verification';
    final subject = isVerify ? 'رمز تفعيل البريد الإلكتروني' : 'رمز إعادة تعيين كلمة المرور';
    final html = _buildHtml(otp: otp, isVerify: isVerify);
    return _cfg.send(to: to, subject: subject, html: html);
  }

  String _buildHtml({required String otp, required bool isVerify}) => '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="UTF-8"></head>
<body style="font-family:Arial,sans-serif;background:#f4f4f4;padding:20px;margin:0;">
  <div style="max-width:480px;margin:0 auto;background:#fff;border-radius:12px;padding:32px;">
    <h2 style="color:#6C63FF;text-align:center;">
      ${isVerify ? '✉️ تفعيل البريد الإلكتروني' : '🔑 إعادة تعيين كلمة المرور'}
    </h2>
    <p style="color:#333;font-size:15px;">
      ${isVerify ? 'استخدم الرمز التالي لتفعيل حسابك:' : 'استخدم الرمز التالي لإعادة تعيين كلمة المرور:'}
    </p>
    <div style="background:#f0eeff;border-radius:10px;padding:20px;text-align:center;margin:24px 0;">
      <span style="font-size:36px;font-weight:bold;letter-spacing:12px;color:#6C63FF;">$otp</span>
    </div>
    <p style="color:#666;font-size:13px;">⏱️ صالح لمدة <strong>10 دقائق</strong> فقط.</p>
  </div>
</body>
</html>''';
}

// ── Config base ──────────────────────────────────────────────────────────────
abstract class _Config {
  Future<bool> send({required String to, required String subject, required String html});
}

// ── Gmail SMTP ───────────────────────────────────────────────────────────────
class _GmailConfig extends _Config {
  final String user, password, from;
  _GmailConfig({required this.user, required this.password, required this.from});

  @override
  Future<bool> send({required String to, required String subject, required String html}) async {
    try {
      final msg = mailer.Message()
        ..from = mailer.Address(from.isEmpty ? user : from, 'تطبيق الخير')
        ..recipients.add(to)
        ..subject = subject
        ..html = html;
      await mailer.send(msg, gmail(user, password));
      print('📧 Gmail → $to');
      return true;
    } catch (e) {
      print('❌ Gmail error: $e');
      return false;
    }
  }
}

// ── Brevo API ────────────────────────────────────────────────────────────────
class _BrevoConfig extends _Config {
  final String apiKey, from;
  _BrevoConfig({required this.apiKey, required this.from});

  @override
  Future<bool> send({required String to, required String subject, required String html}) async {
    try {
      final resp = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {'api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': {'name': 'تطبيق الخير', 'email': from},
          'to': [{'email': to}],
          'subject': subject,
          'htmlContent': html,
        }),
      );
      if (resp.statusCode == 201) { print('📧 Brevo → $to'); return true; }
      print('❌ Brevo ${resp.statusCode}: ${resp.body}');
      return false;
    } catch (e) { print('❌ Brevo: $e'); return false; }
  }
}

// ── Resend API ───────────────────────────────────────────────────────────────
class _ResendConfig extends _Config {
  final String apiKey, from;
  _ResendConfig({required this.apiKey, required this.from});

  @override
  Future<bool> send({required String to, required String subject, required String html}) async {
    try {
      final resp = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({'from': 'تطبيق الخير <$from>', 'to': [to], 'subject': subject, 'html': html}),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) { print('📧 Resend → $to'); return true; }
      print('❌ Resend ${resp.statusCode}: ${resp.body}');
      return false;
    } catch (e) { print('❌ Resend: $e'); return false; }
  }
}
