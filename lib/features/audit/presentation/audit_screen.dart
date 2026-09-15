import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/audit/data/repositories/sqlite_audit_repository.dart';

final auditRepositoryProvider = Provider((ref) => SqliteAuditRepository(ref.watch(databaseProvider)));
final auditLogsProvider = FutureProvider((ref) => ref.watch(auditRepositoryProvider).getLogs());

class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: logsAsync.when(
        data: (logs) => ListView.separated(
          itemCount: logs.length,
          separatorBuilder: (context, _) => const Divider(),
          itemBuilder: (context, idx) {
            final log = logs[idx];
            return ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: Text(log.action),
              subtitle: Text(log.details ?? 'No details'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(log.userName),
                  Text(DateFormat('dd MMM HH:mm').format(log.timestamp), style: const TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
