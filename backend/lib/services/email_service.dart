import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Sends transactional emails via Resend HTTP API.
///
/// Configure via environment variables:
///   RESEND_API_KEY  – API key from resend.com (required)
///   EMAIL_FROM      – sender address (default: onboarding@resend.dev)
class EmailService {
  final String _apiKey;
  final String _from;

  EmailService._({required String apiKey, required String from})
      : _apiKey = apiKey,
        _from = from;

  /// Returns null if RESEND_API_KEY is not set.
  static EmailService? fromEnv() {
    // Support both RESEND_API_KEY and legacy SMTP_PASSWORD (Resend API key)
    final apiKey = Platform.environment['RESEND_API_KEY'] ??
        Platform.environment['SMTP_PASSWORD'] ??
        '';
    if (apiKey.isEmpty || !apiKey.startsWith('re_')) return null;

    final from =
        Platform.environment['EMAIL_FROM'] ?? 'onboarding@resend.dev';
    return EmailService._(apiKey: apiKey, from: from);
  }

  /// Send OTP email. Returns true on success, false on failure.
  Future<bool> sendOtp({
    required String to,
    required String otp,
    required String purpose, // 'email_verification' | 'password_reset'
  }) async {
    final isVerification = purpose == 'email_verification';
    final subject = isVerification
        ? 'رمز تفعيل البريد الإلكتروني'
        : 'رمز إعادة تعيين كلمة المرور';

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
        print('📧 Email sent to $to via Resend (purpose: $purpose)');
        return true;
      } else {
        print('❌ Resend API error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Email error: $e');
      return false;
    }
  }
}
