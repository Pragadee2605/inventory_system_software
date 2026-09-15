abstract class AuditRepository {
  Future<void> logAction({required int userId, required String action, String? details});
  Future<List<AuditLog>> getLogs();
}

class AuditLog {
  final int id;
  final int userId;
  final String userName;
  final String action;
  final String? details;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    this.details,
    required this.timestamp,
  });
}
