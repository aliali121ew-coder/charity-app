import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [LocalStorage] implementation (gotrue) that persists the Supabase session
/// in the platform's encrypted secure storage (Keychain on iOS, Encrypted
/// SharedPreferences / Keystore on Android) instead of plain SharedPreferences.
///
/// This keeps the Supabase access/refresh tokens out of world-readable
/// on-device storage.
///
// VERIFY: gotrue LocalStorage API — this overrides the five members of the
// abstract `LocalStorage` class as of supabase_flutter ^2.8.0 (gotrue 2.x):
//   initialize(), hasAccessToken(), accessToken(),
//   persistSession(String), removePersistedSession().
// If a future gotrue version changes this surface, adjust the overrides here.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  /// Key under which the stringified Supabase session is stored.
  static const String _sessionKey = 'supabase.session';

  @override
  Future<void> initialize() async {
    // Nothing to initialize for FlutterSecureStorage.
  }

  @override
  Future<bool> hasAccessToken() async {
    return _storage.containsKey(key: _sessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return _storage.read(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
