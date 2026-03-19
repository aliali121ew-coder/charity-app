import 'package:equatable/equatable.dart';
import '../../../../core/permissions/role.dart';

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final DateTime lastLogin;
  final bool isActive;
  final Set<Permission>? customPermissions;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.lastLogin,
    this.isActive = true,
    this.customPermissions,
  });

  Set<Permission> get effectivePermissions =>
      customPermissions ?? defaultPermissions[role] ?? {};

  bool hasPermission(Permission permission) =>
      effectivePermissions.contains(permission);

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    DateTime? lastLogin,
    bool? isActive,
    Set<Permission>? customPermissions,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      customPermissions: customPermissions ?? this.customPermissions,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, isActive];
}
