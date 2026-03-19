enum UserRole { admin, employee }

class User {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        // Note: passwordHash is never returned in API responses
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String? ?? '',
        role: UserRole.values.byName(json['role'] as String),
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Returns user data safe for API responses (no password)
  Map<String, dynamic> toPublicJson() {
    final json = toJson();
    json.remove('passwordHash');
    return json;
  }
}
