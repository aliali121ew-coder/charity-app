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

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
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
      final user = role == 'admin'
          ? UserModel.admin(
              id: userId,
              name: 'مدير النظام',
              email: 'admin@charity.org',
            )
          : UserModel.employee(
              id: userId,
              name: 'موظف',
              email: 'employee@charity.org',
            );
      return AuthState(user: user);
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

      final role = (user['role'] ?? 'employee').toString();
      final userId = (user['id'] ?? '').toString();
      final name = (user['name'] ?? '').toString();
      final emailRes = (user['email'] ?? email).toString();

      final userModel = role == 'admin'
          ? UserModel.admin(id: userId, name: name, email: emailRes)
          : UserModel.employee(id: userId, name: name, email: emailRes);

      await _prefs.setString(AppConstants.prefAuthToken, token);
      await _prefs.setString(AppConstants.prefUserRole, role);
      await _prefs.setString(AppConstants.prefUserId, userId);
      state = state.copyWith(user: userModel, isLoading: false);
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

  Future<void> logout() async {
    await _prefs.remove(AppConstants.prefAuthToken);
    await _prefs.remove(AppConstants.prefUserRole);
    await _prefs.remove(AppConstants.prefUserId);
    state = const AuthState();
    _routerNotifier.notify();
  }
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier();
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
