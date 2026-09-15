import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/auth/data/repositories/sqlite_auth_repository.dart';
import 'package:inventory_system_software/features/auth/data/services/password_service.dart';
import 'package:inventory_system_software/features/auth/domain/models/auth_user.dart';
import 'package:inventory_system_software/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SqliteAuthRepository(db, PasswordService());
});

final authStateProvider = AsyncNotifierProvider<AuthState, AuthUser?>(AuthState.new);

class AuthState extends AsyncNotifier<AuthUser?> {
  @override
  FutureOr<AuthUser?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(username, password);
      if (user == null) throw Exception('Invalid username or password');
      return user;
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    ref.invalidateSelf();
  }

  Future<void> setupAdmin({
    required String username,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.createInitialAdmin(
        username: username,
        password: password,
        fullName: fullName,
      );
      ref.invalidate(hasUsersProvider);
      return await repo.login(username, password);
    });
  }
}

final hasUsersProvider = FutureProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).hasUsers();
});

final userListProvider = AsyncNotifierProvider<UserListNotifier, List<AuthUser>>(UserListNotifier.new);

class UserListNotifier extends AsyncNotifier<List<AuthUser>> {
  @override
  FutureOr<List<AuthUser>> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.getAllUsers();
  }

  Future<void> createUser({
    required String username,
    required String fullName,
    required String password,
    required String roleName,
    String? email,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.createUser(
        username: username,
        fullName: fullName,
        password: password,
        roleName: roleName,
        email: email,
        phone: phone,
      );
      return repo.getAllUsers();
    });
  }

  Future<void> updateUser({
    required int id,
    required String fullName,
    required String roleName,
    String? email,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateUser(
        id: id,
        fullName: fullName,
        roleName: roleName,
        email: email,
        phone: phone,
      );
      return repo.getAllUsers();
    });
  }

  Future<void> toggleUserStatus(int id, UserStatus currentStatus) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final newStatus = currentStatus == UserStatus.active ? UserStatus.inactive : UserStatus.active;
      await repo.setUserStatus(id, newStatus);
      return repo.getAllUsers();
    });
  }

  Future<void> changePassword(int id, String newPassword) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.changePassword(id, newPassword);
  }
}
