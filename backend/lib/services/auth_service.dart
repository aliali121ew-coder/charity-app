import 'dart:convert';
import 'dart:math';
import 'package:charity_backend/models/user.dart';

/// Authentication service — handles login, token generation, and validation.
/// TODO: Replace token generation with proper JWT (package:dart_jsonwebtoken)
class AuthService {
  // In-memory users — replace with database lookup
  static final List<User> _users = [
    User(
      id: 'user_001',
      name: 'مدير النظام',
      email: 'admin@charity.org',
      passwordHash: _simpleHash('admin123'),
      role: UserRole.admin,
      createdAt: DateTime(2024, 1, 1),
    ),
    User(
      id: 'user_002',
      name: 'أحمد محمد',
      email: 'employee@charity.org',
      passwordHash: _simpleHash('emp123'),
      role: UserRole.employee,
      createdAt: DateTime(2024, 1, 15),
    ),
    User(
      id: 'user_003',
      name: 'سارة خالد',
      email: 'sarah@charity.org',
      passwordHash: _simpleHash('sara123'),
      role: UserRole.employee,
      createdAt: DateTime(2024, 2, 1),
    ),
  ];

  // In-memory active tokens — replace with Redis/DB in production
  static final Map<String, String> _activeTokens = {};

  /// Attempt login — returns token + user on success, null on failure
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final user = _users.cast<User?>().firstWhere(
          (u) => u?.email.toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );

    if (user == null) return null;
    if (user.passwordHash != _simpleHash(password)) return null;
    if (!user.isActive) return null;

    final token = _generateToken(user.id);
    _activeTokens[token] = user.id;

    return {
      'token': token,
      'user': user.toPublicJson(),
      'expiresIn': 86400, // 24 hours
    };
  }

  /// Validate token — returns userId or null if invalid
  String? validateToken(String token) => _activeTokens[token];

  /// Logout — invalidates token
  void logout(String token) => _activeTokens.remove(token);

  static String _generateToken(String userId) {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Simple hash — replace with bcrypt in production
  static String _simpleHash(String input) {
    var hash = 0;
    for (final char in input.codeUnits) {
      hash = (hash * 31 + char) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
