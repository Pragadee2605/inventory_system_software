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
