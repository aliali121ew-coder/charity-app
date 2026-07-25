import 'package:charity_app/core/permissions/role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final Set<Permission> permissions;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
    required this.permissions,
    this.isActive = true,
  });

  bool hasPermission(Permission permission) => permissions.contains(permission);

  factory UserModel.admin({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      role: UserRole.admin,
      avatarUrl: avatarUrl,
      permissions: defaultPermissions[UserRole.admin]!,
    );
  }

  factory UserModel.employee({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      role: UserRole.employee,
      avatarUrl: avatarUrl,
      permissions: defaultPermissions[UserRole.employee]!,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? phone,
    Set<Permission>? permissions,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
    );
  }
}
