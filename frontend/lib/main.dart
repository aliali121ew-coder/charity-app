import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/app.dart';
import 'package:charity_app/shared/providers/app_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:charity_app/core/supabase/supabase_config.dart';
import 'package:charity_app/core/supabase/secure_local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the Cairo font files bundled in assets/fonts/ and never fetch fonts
  // over the network — removes the per-session stall on first text paint.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock to portrait + landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);


  // Edge-to-edge — إزالة الحواف السوداء من جميع الصفحات
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );


  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Supabase (اضبط المفاتيح عبر --dart-define أو في SupabaseConfig)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CharityApp(),
    ),
  );
}
