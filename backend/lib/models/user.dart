enum UserRole { admin, employee, beneficiary }

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? username;
  final String? passwordHash;
  final String? googleId;
  final UserRole role;
  final bool isActive;
  final bool emailVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.username,
    this.passwordHash,
    this.googleId,
    this.role = UserRole.beneficiary,
    this.isActive = false,
    this.emailVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toPublicJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'username': username,
        'role': role.name,
        'isActive': isActive,
        'emailVerified': emailVerified,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        username: json['username'] as String?,
        passwordHash: json['passwordHash'] as String?,
        googleId: json['googleId'] as String?,
        role: UserRole.values.byName(json['role'] as String? ?? 'beneficiary'),
        isActive: json['isActive'] as bool? ?? false,
        emailVerified: json['emailVerified'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  factory User.fromRow(Map<String, dynamic> row) => User(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String,
        phone: row['phone'] as String?,
        username: row['username'] as String?,
        passwordHash: row['password_hash'] as String?,
        googleId: row['google_id'] as String?,
        role: UserRole.values.byName(row['role'] as String? ?? 'beneficiary'),
        isActive: row['is_active'] as bool? ?? false,
        emailVerified: row['email_verified'] as bool? ?? false,
        createdAt: row['created_at'] is DateTime
            ? (row['created_at'] as DateTime)
            : DateTime.parse(row['created_at'].toString()),
      );

  User copyWith({
    String? passwordHash,
    String? googleId,
    bool? isActive,
    bool? emailVerified,
  }) =>
      User(
        id: id,
        name: name,
        email: email,
        phone: phone,
        username: username,
        passwordHash: passwordHash ?? this.passwordHash,
        googleId: googleId ?? this.googleId,
        role: role,
        isActive: isActive ?? this.isActive,
        emailVerified: emailVerified ?? this.emailVerified,
        createdAt: createdAt,
      );
}
