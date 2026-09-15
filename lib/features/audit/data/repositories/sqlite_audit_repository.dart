import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/audit/domain/repositories/audit_repository.dart' as model;

class SqliteAuditRepository implements model.AuditRepository {
  final AppDatabase _db;

  SqliteAuditRepository(this._db);

  @override
  Future<void> logAction({required int userId, required String action, String? details}) async {
    await _db.into(_db.auditLogs).insert(
      AuditLogsCompanion.insert(
        userId: userId,
        action: action,
        details: Value(details),
      ),
    );
  }

  @override
  Future<List<model.AuditLog>> getLogs() async {
    final query = _db.select(_db.auditLogs).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.auditLogs.userId)),
    ]);
    query.orderBy([OrderingTerm.desc(_db.auditLogs.timestamp)]);

    final rows = await query.get();
    return rows.map((row) {
      final log = row.readTable(_db.auditLogs);
      final user = row.readTable(_db.users);
      return model.AuditLog(
        id: log.id,
        userId: log.userId,
        userName: user.fullName,
        action: log.action,
        details: log.details,
        timestamp: log.timestamp,
      );
    }).toList();
  }
}
