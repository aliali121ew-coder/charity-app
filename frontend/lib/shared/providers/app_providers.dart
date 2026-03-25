import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/core/constants/app_constants.dart';
import 'package:charity_app/shared/models/user_model.dart';

// ── Shared Preferences ───────────────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main');
});

// ── Locale ───────────────────────────────────────────────────────────────────
class LocaleNotifier extends Notifier<Locale> {
  late final SharedPreferences _prefs;

  @override
  Locale build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final saved = _prefs.getString(AppConstants.prefLocale) ?? 'ar';
    return Locale(saved);
  }

  void setLocale(Locale locale) {
    state = locale;
    _prefs.setString(AppConstants.prefLocale, locale.languageCode);
  }

  void toggle() => setLocale(
        state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'),
      );
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

// ── Theme Mode ────────────────────────────────────────────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  late final SharedPreferences _prefs;

  @override
  ThemeMode build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final saved = _prefs.getString(AppConstants.prefThemeMode) ?? 'light';
    return saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString(
        AppConstants.prefThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  void toggle() => setThemeMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  /// Set when user registered but hasn't verified email yet.
  final String? pendingVerificationEmail;

  /// Debug only: OTP code returned by server in non-production mode.
  final String? debugVerificationCode;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isGuest = false,
    this.pendingVerificationEmail,
    this.debugVerificationCode,
  });

  bool get isAuthenticated => user != null;
  bool get hasAccess => isAuthenticated || isGuest;
  bool get isPendingVerification => pendingVerificationEmail != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isGuest,
    String? pendingVerificationEmail,
    String? debugVerificationCode,
    bool clearUser = false,
    bool clearError = false,
    bool clearPending = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isGuest: isGuest ?? this.isGuest,
      pendingVerificationEmail: clearPending
          ? null
          : pendingVerificationEmail ?? this.pendingVerificationEmail,
      debugVerificationCode: clearPending
          ? null
          : debugVerificationCode ?? this.debugVerificationCode,
    );
  }
}

class AuthRouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class AuthNotifier extends Notifier<AuthState> {
  late final SharedPreferences _prefs;
  late final AuthRouterNotifier _routerNotifier;
  late final Uri _apiBase;

  @override
  AuthState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _routerNotifier = ref.watch(authRouterNotifierProvider);
    _apiBase = Uri.parse(const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://charity-backend-production-0223.up.railway.app',
    ));
    final token = _prefs.getString(AppConstants.prefAuthToken);
    final role = _prefs.getString(AppConstants.prefUserRole);
    final userId = _prefs.getString(AppConstants.prefUserId);
    if (token != null && role != null && userId != null) {
      final savedName = _prefs.getString(AppConstants.prefUserName) ?? '';
      final savedEmail = _prefs.getString(AppConstants.prefUserEmail) ?? '';
      final user = role == 'admin'
          ? UserModel.admin(id: userId, name: savedName, email: savedEmail)
          : role == 'employee'
              ? UserModel.employee(id: userId, name: savedName, email: savedEmail)
              : UserModel.beneficiary(id: userId, name: savedName, email: savedEmail);
      return AuthState(user: user);
    }
    if (_prefs.getBool(AppConstants.prefIsGuest) == true) {
      return const AuthState(isGuest: true);
    }
    return const AuthState();
  }

  bool get isLoggedIn => state.isAuthenticated;

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await http.post(
        _apiBase.resolve('/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final decoded = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};

      // Email not verified → go to verification screen
      if (resp.statusCode == 403 &&
          decoded['error'] == 'email_not_verified') {
        final pendingEmail =
            decoded['email']?.toString() ?? email;
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          pendingVerificationEmail: pendingEmail,
        );
        _routerNotifier.notify();
        return false;
      }

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        state = state.copyWith(
          isLoading: false,
          error: decoded['error']?.toString() ?? 'invalid_credentials',
          clearUser: true,
        );
        return false;
      }

      final token = decoded['token']?.toString();
      final user = decoded['user'] as Map<String, dynamic>?;
      if (token == null || user == null) {
        state = state.copyWith(
            isLoading: false, error: 'server_error', clearUser: true);
        return false;
      }

      await _saveSession(token, user);
      _routerNotifier.notify();
      return true;
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'server_error', clearUser: true);
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<bool> loginWithGoogle(String googleIdToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await http.post(
        _apiBase.resolve('/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleIdToken}),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        state = state.copyWith(
            isLoading: false, error: 'google_auth_error', clearUser: true);
        return false;
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = decoded['token']?.toString();
      final user = decoded['user'] as Map<String, dynamic>?;
      if (token == null || user == null) {
        state = state.copyWith(
            isLoading: false, error: 'server_error', clearUser: true);
        return false;
      }

      await _saveSession(token, user);
      _routerNotifier.notify();
      return true;
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'server_error', clearUser: true);
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  /// Returns null on success (pending verification), error string on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await http.post(
        _apiBase.resolve('/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'username': username,
          'password': password,
        }),
      );
      final decoded = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final msg = decoded['error']?.toString() ?? 'register_error';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }

      // Registration success → pending email verification
      final pendingEmail = decoded['email']?.toString() ?? email;
      state = state.copyWith(
        isLoading: false,
        clearError: true,
        pendingVerificationEmail: pendingEmail,
        debugVerificationCode: decoded['debug_code']?.toString(),
      );
      _routerNotifier.notify();
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

  // ── Verify Email ──────────────────────────────────────────────────────────
  /// Returns null on success, error string on failure.
  Future<String?> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await http.post(
        _apiBase.resolve('/api/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      final decoded = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final msg = decoded['error']?.toString() ?? 'invalid_code';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }

      // Success: user is now verified — log them in
      final token = decoded['token']?.toString();
      final user = decoded['user'] as Map<String, dynamic>?;
      if (token != null && user != null) {
        await _saveSession(token, user);
        state = state.copyWith(isLoading: false, clearPending: true);
      } else {
        state = state.copyWith(isLoading: false, clearPending: true);
      }
      _routerNotifier.notify();
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

  // ── Resend Verification ───────────────────────────────────────────────────
  Future<String?> resendVerification(String email) async {
    try {
      final resp = await http.post(
        _apiBase.resolve('/api/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return 'resend_error';
      }
      // Update debug code if returned (non-production)
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['debug_code'] != null) {
        state = state.copyWith(debugVerificationCode: body['debug_code'] as String);
      }
      return null;
    } catch (_) {
      return 'server_error';
    }
  }

  // ── Guest ─────────────────────────────────────────────────────────────────
  Future<void> loginAsGuest() async {
    await _prefs.setBool(AppConstants.prefIsGuest, true);
    state = const AuthState(isGuest: true);
    _routerNotifier.notify();
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<String?> sendPasswordResetOtp(String emailOrPhone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await http.post(
        _apiBase.resolve('/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailOrPhone': emailOrPhone}),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        state = state.copyWith(isLoading: false);
        return 'send_otp_error';
      }
      // Store debug_otp if server returns it (non-production or email failed)
      final body = resp.body.isNotEmpty
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : <String, dynamic>{};
      state = state.copyWith(
        isLoading: false,
        debugVerificationCode: body['debug_otp']?.toString(),
      );
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

  Future<String?> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await http.post(
        _apiBase.resolve('/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': emailOrPhone,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      state = state.copyWith(isLoading: false);
      if (resp.statusCode < 200 || resp.statusCode >= 300) return 'reset_error';
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _prefs.remove(AppConstants.prefAuthToken);
    await _prefs.remove(AppConstants.prefUserRole);
    await _prefs.remove(AppConstants.prefUserId);
    await _prefs.remove(AppConstants.prefUserName);
    await _prefs.remove(AppConstants.prefUserEmail);
    await _prefs.remove(AppConstants.prefIsGuest);
    state = const AuthState();
    _routerNotifier.notify();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  Future<void> _saveSession(
      String token, Map<String, dynamic> user) async {
    final role = (user['role'] ?? 'beneficiary').toString();
    final userId = (user['id'] ?? '').toString();
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();

    final userModel = role == 'admin'
        ? UserModel.admin(id: userId, name: name, email: email)
        : role == 'employee'
            ? UserModel.employee(id: userId, name: name, email: email)
            : UserModel.beneficiary(id: userId, name: name, email: email);

    await _prefs.setString(AppConstants.prefAuthToken, token);
    await _prefs.setString(AppConstants.prefUserRole, role);
    await _prefs.setString(AppConstants.prefUserId, userId);
    await _prefs.setString(AppConstants.prefUserName, name);
    await _prefs.setString(AppConstants.prefUserEmail, email);
    await _prefs.remove(AppConstants.prefIsGuest);

    state = state.copyWith(
        user: userModel, isLoading: false, isGuest: false,
        clearPending: true);
  }
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier();
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
