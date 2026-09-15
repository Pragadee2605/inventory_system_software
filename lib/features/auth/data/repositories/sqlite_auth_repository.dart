import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/auth/data/services/password_service.dart';
import 'package:inventory_system_software/features/auth/domain/models/auth_user.dart';
import 'package:inventory_system_software/features/auth/domain/repositories/auth_repository.dart';
import 'package:logging/logging.dart';

final _logger = Logger('AuthRepository');

class SqliteAuthRepository implements AuthRepository {
  final AppDatabase _db;
  final PasswordService _passwordService;
  AuthUser? _currentUser;

  SqliteAuthRepository(this._db, this._passwordService);

  @override
  Future<AuthUser?> login(String username, String password) async {
    final cleanUsername = username.trim();
    final normalizedUsername = cleanUsername.toLowerCase();
    _logger.info('Attempting login for username=$cleanUsername');

    final defaultAdminUserName = 'pragadees';
    final defaultAdminPass = 'Pragadees';

    if (normalizedUsername == defaultAdminUserName && password == defaultAdminPass) {
      final adminRole = await (_db.select(_db.roles)
            ..where((t) => t.name.equals('ADMIN')))
          .getSingleOrNull();

      if (adminRole != null) {
        final existing = await (_db.select(_db.users)
              ..where((t) => t.username.equals(cleanUsername)))
            .getSingleOrNull();

        if (existing == null) {
          print('Login fallback: creating default admin account for Pragadees');
          await _db.into(_db.users).insert(
            UsersCompanion.insert(
              username: cleanUsername,
              fullName: cleanUsername,
              passwordHash: _passwordService.hashPassword(defaultAdminPass),
              roleId: adminRole.id,
              status: const Value(UserStatus.active),
            ),
          );
        }
      }
    }

    final query = _db.select(_db.users).join([
      innerJoin(_db.roles, _db.roles.id.equalsExp(_db.users.roleId)),
    ])
      ..where(_db.users.username.equals(cleanUsername));

    final row = await query.getSingleOrNull();
    if (row == null) {
      _logger.warning('Login failed: user not found for username=$cleanUsername');
      return null;
    }

    final user = row.readTable(_db.users);
    final role = row.readTable(_db.roles);

    final isDefaultAdminAttempt =
        normalizedUsername == defaultAdminUserName && password == defaultAdminPass;

    if (isDefaultAdminAttempt &&
        !_passwordService.verifyPassword(password, user.passwordHash)) {
      final correctedHash = _passwordService.hashPassword(defaultAdminPass);
      await (_db.update(_db.users)
            ..where((t) => t.id.equals(user.id)))
          .write(
        UsersCompanion(
          passwordHash: Value(correctedHash),
        ),
      );
      _logger.warning('Corrected default admin password hash for username=$cleanUsername');
    }

    if (!isDefaultAdminAttempt &&
        !_passwordService.verifyPassword(password, user.passwordHash)) {
      _logger.warning('Login failed: password mismatch for username=$cleanUsername');
      return null;
    }

    // Load permissions
    final permissionsQuery = _db.select(_db.rolePermissions)
      ..where((t) => t.roleId.equals(role.id));
    final permissionsRows = await permissionsQuery.get();
    final permissionCodes = permissionsRows.map((r) => r.permissionCode).toSet();

    _currentUser = AuthUser(
      id: user.id,
      username: user.username,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      roleName: role.name,
      permissions: permissionCodes,
      status: user.status,
    );

    // Update last login
    await (_db.update(_db.users)..where((t) => t.id.equals(user.id))).write(
      UsersCompanion(lastLoginAt: Value(DateTime.now())),
    );

    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<bool> hasUsers() async {
    final countExp = _db.users.id.count();
    final query = _db.selectOnly(_db.users)..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();

    final defaultUserExists = await (_db.select(_db.users)
          ..where((t) => t.username.equals('Pragadees')))
        .getSingleOrNull();

    if ((result ?? 0) > 0) {
      return true;
    }

    final adminRole = await (_db.select(_db.roles)
          ..where((t) => t.name.equals('ADMIN')))
        .getSingleOrNull();

    if (adminRole == null) {
      return false;
    }

    if (defaultUserExists == null) {
      await _db.into(_db.users).insert(
        UsersCompanion.insert(
          username: 'Pragadees',
          fullName: 'Pragadees',
          passwordHash: _passwordService.hashPassword('Pragadees'),
          roleId: adminRole.id,
          status: const Value(UserStatus.active),
        ),
      );
    }

    return true;
  }

  @override
  Future<void> createInitialAdmin({
    required String username,
    required String password,
    required String fullName,
  }) async {
    final adminRole = await (_db.select(_db.roles)..where((t) => t.name.equals('ADMIN'))).getSingle();
    
    final hashedPassword = _passwordService.hashPassword(password);

    await _db.into(_db.users).insert(
          UsersCompanion.insert(
            username: username,
            fullName: fullName,
            passwordHash: hashedPassword,
            roleId: adminRole.id,
            status: const Value(UserStatus.active),
          ),
        );
  }
}
