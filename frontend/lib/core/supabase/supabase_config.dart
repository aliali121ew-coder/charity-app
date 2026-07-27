import 'package:supabase_flutter/supabase_flutter.dart';

/// إعدادات اتصال Supabase.
///
/// مرّر القيم وقت التشغيل عبر --dart-define (موصى به، لا تُخزّن المفاتيح في الكود):
///   flutter run \
///     --dart-define=SUPABASE_URL=https://hgufcwdshyznpykerxox.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=<anon-key>
///
/// الـ anon key عام (public) ومحميّ بسياسات RLS — لكن لا تضع service_role key هنا أبداً.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hgufcwdshyznpykerxox.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // ضعه عبر --dart-define أو الصقه هنا مؤقتاً للتجربة
  );
}

/// اختصار للوصول لعميل Supabase في أي مكان بعد التهيئة في main().
SupabaseClient get supabase => Supabase.instance.client;
