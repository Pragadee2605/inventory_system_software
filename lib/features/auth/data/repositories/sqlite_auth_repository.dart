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
    final cleanInput = username.trim();
    if (cleanInput.isEmpty || password.isEmpty) {
      throw Exception('Username and password are required.');
    }

    _logger.info('Attempting login for input=$cleanInput');

    // Query user by username or email
    final query = _db.select(_db.users).join([
      innerJoin(_db.roles, _db.roles.id.equalsExp(_db.users.roleId)),
    ])..where(_db.users.username.equals(cleanInput) | _db.users.email.equals(cleanInput));

    final row = await query.getSingleOrNull();
    if (row == null) {
      _logger.warning('Login failed: user not found for $cleanInput');
      throw Exception('Invalid username or password');
    }

    final user = row.readTable(_db.users);
    final role = row.readTable(_db.roles);

    // Check account status
    if (user.status == UserStatus.inactive) {
      _logger.warning('Login rejected: user account $cleanInput is disabled.');
      throw Exception('Account is disabled. Please contact an administrator.');
    }

    // Verify password hash
    final isValidPassword = _passwordService.verifyPassword(password, user.passwordHash);
    if (!isValidPassword) {
      _logger.warning('Login failed: password mismatch for $cleanInput');
      throw Exception('Invalid username or password');
    }

    // Load permissions for role
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

    // Update last login timestamp
    await (_db.update(_db.users)..where((t) => t.id.equals(user.id))).write(
      UsersCompanion(lastLoginAt: Value(DateTime.now())),
    );

    // Audit Log entry
    await _db.into(_db.auditLogs).insert(
      AuditLogsCompanion.insert(
        userId: user.id,
        action: 'LOGIN',
        details: Value('User logged in successfully: ${user.username}'),
      ),
    );

    return _currentUser;
  }

  @override
  Future<void> logout() async {
    if (_currentUser != null) {
      await _db.into(_db.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: _currentUser!.id,
          action: 'LOGOUT',
          details: Value('User logged out: ${_currentUser!.username}'),
        ),
      );
    }
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
    return (result ?? 0) > 0;
  }

  @override
  Future<void> createInitialAdmin({
    required String username,
    required String password,
    required String fullName,
  }) async {
    final existingRole = await (_db.select(_db.roles)..where((t) => t.name.equals('ADMIN'))).getSingleOrNull();

    late final int adminRoleId;
    if (existingRole == null) {
      adminRoleId = await _db.into(_db.roles).insert(
        RolesCompanion.insert(name: 'ADMIN', description: const Value('Administrator with full access')),
      );
    } else {
      adminRoleId = existingRole.id;
    }

    final hashedPassword = _passwordService.hashPassword(password);

    final userId = await _db.into(_db.users).insert(
      UsersCompanion.insert(
        username: username,
        fullName: fullName,
        passwordHash: hashedPassword,
        roleId: adminRoleId,
        status: const Value(UserStatus.active),
      ),
    );

    await _db.into(_db.auditLogs).insert(
      AuditLogsCompanion.insert(
        userId: userId,
        action: 'INITIAL_SETUP',
        details: Value('Primary Admin account initialized: $username'),
      ),
    );
  }

  @override
  Future<List<AuthUser>> getAllUsers() async {
    final query = _db.select(_db.users).join([
      innerJoin(_db.roles, _db.roles.id.equalsExp(_db.users.roleId)),
    ]);

    final rows = await query.get();
    final usersList = <AuthUser>[];

    for (final row in rows) {
      final u = row.readTable(_db.users);
      final r = row.readTable(_db.roles);

      final permissionsQuery = _db.select(_db.rolePermissions)
        ..where((t) => t.roleId.equals(r.id));
      final permissionsRows = await permissionsQuery.get();
      final permissionCodes = permissionsRows.map((p) => p.permissionCode).toSet();

      usersList.add(
        AuthUser(
          id: u.id,
          username: u.username,
          fullName: u.fullName,
          email: u.email,
          phone: u.phone,
          roleName: r.name,
          permissions: permissionCodes,
          status: u.status,
        ),
      );
    }

    return usersList;
  }

  @override
  Future<int> createUser({
    required String username,
    required String fullName,
    required String password,
    required String roleName,
    String? email,
    String? phone,
  }) async {
    final existingUser = await (_db.select(_db.users)..where((t) => t.username.equals(username))).getSingleOrNull();
    if (existingUser != null) {
      throw Exception('Username "$username" already exists.');
    }

    final role = await (_db.select(_db.roles)..where((t) => t.name.equals(roleName))).getSingleOrNull();
    if (role == null) {
      throw Exception('Role "$roleName" does not exist.');
    }

    final hashedPassword = _passwordService.hashPassword(password);

    final userId = await _db.into(_db.users).insert(
      UsersCompanion.insert(
        username: username,
        fullName: fullName,
        passwordHash: hashedPassword,
        roleId: role.id,
        email: Value(email),
        phone: Value(phone),
        status: const Value(UserStatus.active),
      ),
    );

    if (_currentUser != null) {
      await _db.into(_db.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: _currentUser!.id,
          action: 'CREATE_USER',
          details: Value('Created user "$username" with role $roleName'),
        ),
      );
    }

    return userId;
  }

  @override
  Future<void> updateUser({
    required int id,
    required String fullName,
    required String roleName,
    String? email,
    String? phone,
  }) async {
    final role = await (_db.select(_db.roles)..where((t) => t.name.equals(roleName))).getSingleOrNull();
    if (role == null) {
      throw Exception('Role "$roleName" does not exist.');
    }

    await (_db.update(_db.users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(
        fullName: Value(fullName),
        roleId: Value(role.id),
        email: Value(email),
        phone: Value(phone),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (_currentUser != null) {
      await _db.into(_db.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: _currentUser!.id,
          action: 'UPDATE_USER',
          details: Value('Updated user ID $id: $fullName ($roleName)'),
        ),
      );
    }
  }

  @override
  Future<void> setUserStatus(int id, UserStatus status) async {
    // Prevent disabling the current admin user
    if (_currentUser != null && _currentUser!.id == id && status == UserStatus.inactive) {
      throw Exception('Cannot disable your own active Admin account.');
    }

    await (_db.update(_db.users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (_currentUser != null) {
      await _db.into(_db.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: _currentUser!.id,
          action: status == UserStatus.active ? 'ENABLE_USER' : 'DISABLE_USER',
          details: Value('${status == UserStatus.active ? "Enabled" : "Disabled"} user ID $id'),
        ),
      );
    }
  }

  @override
  Future<void> changePassword(int id, String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    final hashedPassword = _passwordService.hashPassword(newPassword);

    await (_db.update(_db.users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(
        passwordHash: Value(hashedPassword),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (_currentUser != null) {
      await _db.into(_db.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: _currentUser!.id,
          action: 'CHANGE_PASSWORD',
          details: Value('Password changed for user ID $id'),
        ),
      );
    }
  }
}
