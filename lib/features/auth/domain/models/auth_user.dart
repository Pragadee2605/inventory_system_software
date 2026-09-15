import 'package:inventory_system_software/core/database/database.dart';

class AuthUser {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String roleName;
  final Set<String> permissions;
  final UserStatus status;

  AuthUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    required this.roleName,
    required this.permissions,
    required this.status,
  });

  bool hasPermission(String permission) {
    return permissions.contains(permission) || roleName == 'ADMIN';
  }
}
