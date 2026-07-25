abstract class AppConstants {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 100.0;

  // Card elevation / shadow
  static const double cardElevation = 0.0;

  // Drawer width
  static const double drawerWidth = 260.0;

  // KPI card dimensions
  static const double kpiCardHeight = 110.0;
  static const double kpiCardMinWidth = 160.0;

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Shared prefs keys
  static const String prefLocale = 'locale';
  static const String prefThemeMode = 'theme_mode';
  static const String prefRememberMe = 'remember_me';
  static const String prefSavedEmail = 'saved_email';
  static const String prefAuthToken = 'auth_token';
  static const String prefUserRole = 'user_role';
  static const String prefUserId = 'user_id';

  // Pagination
  static const int pageSize = 20;
}
