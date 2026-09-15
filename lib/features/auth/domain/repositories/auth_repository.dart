import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/auth/domain/models/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser?> login(String username, String password);
  Future<void> logout();
  Future<AuthUser?> getCurrentUser();
  Future<bool> hasUsers();
  Future<void> createInitialAdmin({
    required String username,
    required String password,
    required String fullName,
  });

  // User Management Methods
  Future<List<AuthUser>> getAllUsers();
  Future<int> createUser({
    required String username,
    required String fullName,
    required String password,
    required String roleName,
    String? email,
    String? phone,
  });
  Future<void> updateUser({
    required int id,
    required String fullName,
    required String roleName,
    String? email,
    String? phone,
  });
  Future<void> setUserStatus(int id, UserStatus status);
  Future<void> changePassword(int id, String newPassword);
}
