import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:charity_app/core/theme/app_theme.dart';
import 'package:charity_app/core/localization/app_localizations.dart';
import 'package:charity_app/core/router/app_router.dart';
import 'package:charity_app/shared/providers/app_providers.dart';

class CharityApp extends ConsumerWidget {
  const CharityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'منظمة الخير',
      debugShowCheckedModeBanner: false,

      // ── Routing ──────────────────────────────────────────
      routerConfig: router,

      // ── Theme ────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // ── Localization ─────────────────────────────────────
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supported) {
        if (locale != null) {
          for (final supportedLocale in supported) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return const Locale('ar');
      },
    );
  }
}
