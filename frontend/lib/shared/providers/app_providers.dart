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

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

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

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isGuest = false,
  });

  bool get isAuthenticated => user != null;
  bool get hasAccess => isAuthenticated || isGuest;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isGuest,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

// A ChangeNotifier used as go_router's refreshListenable that mirrors auth state.
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
    // Restore guest session
    if (_prefs.getBool(AppConstants.prefIsGuest) == true) {
      return const AuthState(isGuest: true);
    }
    return const AuthState();
  }

  bool get isLoggedIn => state.isAuthenticated;

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final url = _apiBase.resolve('/api/auth/login');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '{"email":"$email","password":"$password"}',
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        state = state.copyWith(
          isLoading: false,
          error: 'invalid_credentials',
          clearUser: true,
        );
        return false;
      }

      final json = resp.body;
      // Minimal decode without extra dependency
      final Map<String, dynamic> decoded =
          (json.isNotEmpty ? (jsonDecode(json) as Map<String, dynamic>) : {});
      final token = decoded['token']?.toString();
      final user = decoded['user'] as Map<String, dynamic>?;
      if (token == null || user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'server_error',
          clearUser: true,
        );
        return false;
      }

      final role = (user['role'] ?? 'user').toString();
      final userId = (user['id'] ?? '').toString();
      final name = (user['name'] ?? '').toString();
      final emailRes = (user['email'] ?? email).toString();

      final userModel = role == 'admin'
          ? UserModel.admin(id: userId, name: name, email: emailRes)
          : role == 'employee'
              ? UserModel.employee(id: userId, name: name, email: emailRes)
              : UserModel.beneficiary(
                  id: userId, name: name, email: emailRes);

      await _prefs.setString(AppConstants.prefAuthToken, token);
      await _prefs.setString(AppConstants.prefUserRole, role);
      await _prefs.setString(AppConstants.prefUserId, userId);
      await _prefs.setString(AppConstants.prefUserName, name);
      await _prefs.setString(AppConstants.prefUserEmail, emailRes);
      await _prefs.remove(AppConstants.prefIsGuest);
      state = state.copyWith(user: userModel, isLoading: false, isGuest: false);
      _routerNotifier.notify();
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'server_error',
        clearUser: true,
      );
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<bool> loginWithGoogle(String googleIdToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final url = _apiBase.resolve('/api/auth/google');
      final resp = await http.post(
        url,
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

      final role = (user['role'] ?? 'beneficiary').toString();
      final userId = (user['id'] ?? '').toString();
      final name = (user['name'] ?? '').toString();
      final emailRes = (user['email'] ?? '').toString();

      final userModel = role == 'admin'
          ? UserModel.admin(id: userId, name: name, email: emailRes)
          : role == 'employee'
              ? UserModel.employee(id: userId, name: name, email: emailRes)
              : UserModel.beneficiary(id: userId, name: name, email: emailRes);

      await _prefs.setString(AppConstants.prefAuthToken, token);
      await _prefs.setString(AppConstants.prefUserRole, role);
      await _prefs.setString(AppConstants.prefUserId, userId);
      await _prefs.setString(AppConstants.prefUserName, name);
      await _prefs.setString(AppConstants.prefUserEmail, emailRes);
      await _prefs.remove(AppConstants.prefIsGuest);
      state = state.copyWith(user: userModel, isLoading: false, isGuest: false);
      _routerNotifier.notify();
      return true;
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'server_error', clearUser: true);
      return false;
    }
  }

  // ── Guest access ──────────────────────────────────────────────────────────
  Future<void> loginAsGuest() async {
    await _prefs.setBool(AppConstants.prefIsGuest, true);
    state = const AuthState(isGuest: true);
    _routerNotifier.notify();
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<String?> register({
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final url = _apiBase.resolve('/api/auth/register');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': username, // display name = username by default
          'email': email,
          'phone': phone,
          'username': username,
          'password': password,
        }),
      );
      final decoded = resp.body.isNotEmpty
          ? (jsonDecode(resp.body) as Map<String, dynamic>)
          : <String, dynamic>{};

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final msg = decoded['message']?.toString() ?? 'register_error';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }
      // Auto-login after register
      state = state.copyWith(isLoading: false);
      await login(email, password);
      return null; // null = success
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

  // ── Forgot password: request OTP ─────────────────────────────────────────
  Future<String?> sendPasswordResetOtp(String emailOrPhone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final url = _apiBase.resolve('/api/auth/forgot-password');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailOrPhone': emailOrPhone}),
      );
      state = state.copyWith(isLoading: false);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return 'send_otp_error';
      }
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

  // ── Forgot password: reset with OTP ─────────────────────────────────────
  Future<String?> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final url = _apiBase.resolve('/api/auth/reset-password');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': emailOrPhone,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      state = state.copyWith(isLoading: false);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return 'reset_error';
      }
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

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
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier();
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
