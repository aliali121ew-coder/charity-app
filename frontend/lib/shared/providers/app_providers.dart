import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charity_app/core/constants/app_constants.dart';
import 'package:charity_app/shared/models/user_model.dart';

// ── Shared Preferences ───────────────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main');
});

// ── Locale ───────────────────────────────────────────────────────────────────
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getString(AppConstants.prefLocale) ?? 'ar';
  return LocaleNotifier(prefs, Locale(saved));
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  LocaleNotifier(this._prefs, Locale initial) : super(initial);

  void setLocale(Locale locale) {
    state = locale;
    _prefs.setString(AppConstants.prefLocale, locale.languageCode);
  }

  void toggle() => setLocale(
        state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'),
      );
}

// ── Theme Mode ────────────────────────────────────────────────────────────────
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getString(AppConstants.prefThemeMode) ?? 'light';
  final mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  return ThemeModeNotifier(prefs, mode);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs, ThemeMode initial) : super(initial);

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString(
        AppConstants.prefThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  void toggle() => setThemeMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

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

class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  final AuthRouterNotifier _routerNotifier;

  AuthNotifier(this._prefs, this._routerNotifier) : super(const AuthState()) {
    _tryAutoLogin();
  }

  bool get isLoggedIn => state.isAuthenticated;

  void _tryAutoLogin() {
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
      state = state.copyWith(user: user);
      // Don't notify router during init — it will check on first build
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Mock auth — replace with real API later
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'admin@charity.org' && password == 'admin123') {
      final user = UserModel.admin(
        id: 'user_001',
        name: 'مدير النظام',
        email: email,
      );
      await _prefs.setString(AppConstants.prefAuthToken, 'mock_token_admin');
      await _prefs.setString(AppConstants.prefUserRole, 'admin');
      await _prefs.setString(AppConstants.prefUserId, 'user_001');
      state = state.copyWith(user: user, isLoading: false);
      _routerNotifier.notify();
      return true;
    } else if (email == 'employee@charity.org' && password == 'emp123') {
      final user = UserModel.employee(
        id: 'user_002',
        name: 'أحمد محمد',
        email: email,
      );
      await _prefs.setString(AppConstants.prefAuthToken, 'mock_token_employee');
      await _prefs.setString(AppConstants.prefUserRole, 'employee');
      await _prefs.setString(AppConstants.prefUserId, 'user_002');
      state = state.copyWith(user: user, isLoading: false);
      _routerNotifier.notify();
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'invalid_credentials',
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
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final routerNotifier = ref.watch(authRouterNotifierProvider);
  return AuthNotifier(prefs, routerNotifier);
});
