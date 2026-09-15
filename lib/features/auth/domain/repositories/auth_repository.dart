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
}
