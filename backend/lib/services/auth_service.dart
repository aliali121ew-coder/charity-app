/// Authentication service — LEGACY, INTENTIONALLY GUTTED.
///
/// Authentication is now handled entirely by Supabase Auth. The Flutter app
/// authenticates directly with Supabase and sends the Supabase access token
/// (JWT) to this backend, which validates it in the request pipeline
/// (see bin/server.dart `_authMiddleware`).
///
/// The previous in-memory user list, insecure `_simpleHash`, and the
/// `_activeTokens` map have been removed. This class is kept only so existing
/// references keep compiling; it no longer issues or validates tokens.
class AuthService {
  /// Login is no longer performed here — clients authenticate with Supabase.
  /// Always returns null (no session is issued by this backend).
  Future<Map<String, dynamic>?> login(String email, String password) async {
    return null;
  }

  /// Token validation now happens in the Supabase JWT middleware, not here.
  /// Always returns null.
  String? validateToken(String token) => null;

  /// No-op: this backend does not maintain server-side sessions anymore.
  void logout(String token) {}
}
