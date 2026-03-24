import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Sends transactional emails.
/// Supports Brevo (BREVO_API_KEY) or Resend (RESEND_API_KEY).
///   EMAIL_FROM – sender address (must be verified in Brevo/Resend)
class EmailService {
  final String _apiKey;
  final String _from;
  final bool _isBrevo;

  EmailService._({
    required String apiKey,
    required String from,
    required bool isBrevo,
  })  : _apiKey = apiKey,
        _from = from,
        _isBrevo = isBrevo;

  static EmailService? fromEnv() {
    final brevo = Platform.environment['BREVO_API_KEY'] ?? '';
    final resend = Platform.environment['RESEND_API_KEY'] ??
        Platform.environment['SMTP_PASSWORD'] ?? '';
    final from = Platform.environment['EMAIL_FROM'] ?? '';

    if (brevo.isNotEmpty) {
      return EmailService._(apiKey: brevo, from: from, isBrevo: true);
    }
    if (resend.isNotEmpty && resend.startsWith('re_')) {
      return EmailService._(
          apiKey: resend,
          from: from.isEmpty ? 'onboarding@resend.dev' : from,
          isBrevo: false);
    }
    return null;
  }

  Future<bool> sendOtp({
    required String to,
    required String otp,
    required String purpose,
  }) async {
    final isVerification = purpose == 'email_verification';
    final subject = isVerification
        ? 'رمز تفعيل البريد الإلكتروني'
        : 'رمز إعادة تعيين كلمة المرور';

    final html = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="UTF-8"></head>
<body style="font-family:Arial,sans-serif;background:#f4f4f4;padding:20px;margin:0;">
  <div style="max-width:480px;margin:0 auto;background:#fff;border-radius:12px;padding:32px;">
    <h2 style="color:#6C63FF;text-align:center;">
      ${isVerification ? '✉️ تفعيل البريد الإلكتروني' : '🔑 إعادة تعيين كلمة المرور'}
    </h2>
    <p style="color:#333;font-size:15px;">
      ${isVerification ? 'استخدم الرمز التالي لتفعيل حسابك:' : 'استخدم الرمز التالي لإعادة تعيين كلمة المرور:'}
    </p>
    <div style="background:#f0eeff;border-radius:10px;padding:20px;text-align:center;margin:24px 0;">
      <span style="font-size:36px;font-weight:bold;letter-spacing:12px;color:#6C63FF;">$otp</span>
    </div>
    <p style="color:#666;font-size:13px;">⏱️ صالح لمدة <strong>10 دقائق</strong> فقط.</p>
  </div>
</body>
</html>''';

    return _isBrevo
        ? await _sendBrevo(to: to, subject: subject, html: html)
        : await _sendResend(to: to, subject: subject, html: html);
  }

  Future<bool> _sendBrevo({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final senderEmail = _from.isNotEmpty ? _from : 'noreply@mail.com';
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': 'تطبيق الخير', 'email': senderEmail},
          'to': [{'email': to}],
          'subject': subject,
          'htmlContent': html,
        }),
      );
      if (response.statusCode == 201) {
        print('📧 Email sent to $to via Brevo');
        return true;
      }
      print('❌ Brevo error ${response.statusCode}: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Brevo exception: $e');
      return false;
    }
  }

  Future<bool> _sendResend({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'تطبيق الخير <$_from>',
          'to': [to],
          'subject': subject,
          'html': html,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('📧 Email sent to $to via Resend');
        return true;
      }
      print('❌ Resend error ${response.statusCode}: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Resend exception: $e');
      return false;
    }
  }
}
