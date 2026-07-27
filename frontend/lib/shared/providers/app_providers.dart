import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// NOTE: `package:supabase_flutter` exports its own `AuthState` class which would
// collide with the app's `AuthState` defined below. Hide it on import — we still
// get `AuthException`, `OtpType`, `UserAttributes`, `User`, etc.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:charity_app/core/constants/app_constants.dart';
import 'package:charity_app/core/supabase/supabase_config.dart';
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
  final String? debugVerificationCode;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.debugVerificationCode,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    String? debugVerificationCode,
    bool clearUser = false,
    bool clearError = false,
    bool clearDebugVerificationCode = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      debugVerificationCode: clearDebugVerificationCode
          ? null
          : debugVerificationCode ?? this.debugVerificationCode,
    );
  }
}

// A ChangeNotifier used as go_router's refreshListenable that mirrors auth state.
class AuthRouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class AuthNotifier extends StateNotifier<AuthState> {
  // Kept for backward-compat (locale/theme notifiers own their own prefs; we no
  // longer persist auth tokens here — supabase_flutter persists the session).
  // ignore: unused_field
  final SharedPreferences _prefs;
  final AuthRouterNotifier _routerNotifier;

  StreamSubscription<dynamic>? _authSub;

  // When true, an explicit flow (login/register/verify) is driving state, so the
  // onAuthStateChange listener should not clobber it with a parallel refresh.
  bool _handlingExplicitFlow = false;

  AuthNotifier(this._prefs, this._routerNotifier) : super(const AuthState()) {
    _initFromSession();
    _subscribeToAuthChanges();
  }

  bool get isLoggedIn => state.isAuthenticated;

  /// Restore an already-signed-in user on app start (session persisted by
  /// supabase_flutter). Runs asynchronously; does NOT notify the router during
  /// init — go_router checks auth state on its first build.
  void _initFromSession() {
    final session = supabase.auth.currentSession;
    final authUser = session?.user ?? supabase.auth.currentUser;
    if (authUser == null) return;
    () async {
      try {
        final user = await _buildUser(authUser);
        if (!mounted) return;
        state = state.copyWith(user: user);
      } catch (_) {
        // Ignore — user can retry via login if profile fetch fails.
      }
    }();
  }

  /// Keep app auth state in sync with Supabase auth events (token refresh,
  /// sign-in/out from anywhere) and refresh the go_router redirect.
  void _subscribeToAuthChanges() {
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      // Explicit flows already set state + notify; skip to avoid double work.
      if (_handlingExplicitFlow) return;

      final session = data.session;
      final authUser = session?.user;
      if (authUser == null) {
        if (!mounted) return;
        if (state.user != null) {
          state = const AuthState();
          _routerNotifier.notify();
        }
        return;
      }

      try {
        final user = await _buildUser(authUser);
        if (!mounted) return;
        state = state.copyWith(user: user, isLoading: false);
        _routerNotifier.notify();
      } catch (_) {
        // Leave existing state untouched on transient profile-fetch failure.
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Resolve the app UserModel (role + name) for an authenticated Supabase user.
  ///
  /// Reads the caller's own `profiles` row (RLS-permitted) for name/type and
  /// checks `staff_profiles` for a staff role (returns null for non-staff under
  /// RLS — that is expected and fine). Admin staff → [UserModel.admin],
  /// everyone else → [UserModel.employee].
  Future<UserModel> _buildUser(User authUser) async {
    Map<String, dynamic>? profile;
    Map<String, dynamic>? staff;

    try {
      profile = await supabase
          .from('profiles')
          .select('full_name, user_type')
          .eq('id', authUser.id)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    try {
      staff = await supabase
          .from('staff_profiles')
          .select('staff_role')
          .eq('id', authUser.id)
          .maybeSingle();
    } catch (_) {
      staff = null;
    }

    final metaName = authUser.userMetadata?['full_name'] as String?;
    final fullName =
        (profile?['full_name'] as String?) ?? metaName ?? (authUser.email ?? '');
    final email = authUser.email ?? '';
    final staffRole = staff?['staff_role'] as String?;

    if (staffRole == 'admin') {
      return UserModel.admin(id: authUser.id, name: fullName, email: email);
    }
    return UserModel.employee(id: authUser.id, name: fullName, email: email);
  }

  /// Map a Supabase [AuthException] message onto the app's error strings.
  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('invalid email or password')) {
      return 'invalid_credentials';
    }
    return e.message;
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    _handlingExplicitFlow = true;
    try {
      final res =
          await supabase.auth.signInWithPassword(email: email, password: password);
      final authUser = res.user;
      if (authUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'invalid_credentials',
          clearUser: true,
        );
        return false;
      }
      final user = await _buildUser(authUser);
      if (!mounted) return true;
      state = state.copyWith(user: user, isLoading: false);
      _routerNotifier.notify();
      return true;
    } on AuthException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: _mapAuthError(e),
        clearUser: true,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'server_error',
        clearUser: true,
      );
      return false;
    } finally {
      _handlingExplicitFlow = false;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    String? phone,
    String? username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    _handlingExplicitFlow = true;
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'user_type': 'community',
        },
      );

      // Session present → email confirmation disabled, user is signed in now.
      if (res.session != null && res.user != null) {
        final user = await _buildUser(res.user!);
        if (!mounted) return null;
        state = state.copyWith(user: user, isLoading: false);
        _routerNotifier.notify();
        return null;
      }

      // No session → email confirmation required. Stay unauthenticated; the
      // verify page will collect the OTP and call verifyEmail().
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, clearUser: true);
      return null;
    } on AuthException catch (e) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, error: e.message);
      return e.message;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    } finally {
      _handlingExplicitFlow = false;
    }
  }

  Future<String?> sendPasswordResetOtp(String emailOrPhone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await supabase.auth.resetPasswordForEmail(emailOrPhone);
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return null;
    } on AuthException catch (e) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, error: e.message);
      return e.message;
    } catch (_) {
      if (!mounted) return null;
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
    _handlingExplicitFlow = true;
    try {
      await supabase.auth.verifyOTP(
        email: emailOrPhone,
        token: otp,
        type: OtpType.recovery,
      );
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return null;
    } on AuthException catch (e) {
      if (!mounted) return null;
      final err = _isOtpError(e) ? 'invalid_code' : e.message;
      state = state.copyWith(isLoading: false, error: err);
      return err;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    } finally {
      _handlingExplicitFlow = false;
    }
  }

  Future<String?> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    _handlingExplicitFlow = true;
    try {
      final res = await supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
      final authUser = res.user ?? supabase.auth.currentUser;
      if (authUser == null) {
        if (!mounted) return null;
        state = state.copyWith(isLoading: false, error: 'invalid_code');
        return 'invalid_code';
      }
      final user = await _buildUser(authUser);
      if (!mounted) return null;
      state = state.copyWith(user: user, isLoading: false);
      _routerNotifier.notify();
      return null;
    } on AuthException catch (e) {
      if (!mounted) return null;
      final err = _isOtpError(e) ? 'invalid_code' : e.message;
      state = state.copyWith(isLoading: false, error: err);
      return err;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    } finally {
      _handlingExplicitFlow = false;
    }
  }

  Future<String?> resendVerification(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await supabase.auth.resend(type: OtpType.signup, email: email);
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return null;
    } on AuthException catch (e) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, error: e.message);
      return e.message;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false, error: 'server_error');
      return 'server_error';
    }
  }

  Future<void> logout() async {
    _handlingExplicitFlow = true;
    try {
      await supabase.auth.signOut();
    } catch (_) {
      // Ignore sign-out errors — clear local state regardless.
    } finally {
      _handlingExplicitFlow = false;
    }
    if (!mounted) return;
    state = const AuthState();
    _routerNotifier.notify();
  }

  /// True when an [AuthException] indicates a bad/expired OTP token.
  bool _isOtpError(AuthException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('otp') ||
        msg.contains('token') ||
        msg.contains('invalid') ||
        msg.contains('expired');
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
