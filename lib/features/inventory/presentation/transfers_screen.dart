import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/inventory/data/repositories/sqlite_transfer_repository.dart';

final transferRepositoryProvider = Provider((ref) => SqliteTransferRepository(ref.watch(databaseProvider)));
final transferListProvider = FutureProvider((ref) => ref.watch(transferRepositoryProvider).getAllTransfers());

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transferListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Transfers')),
      body: transfersAsync.when(
        data: (transfers) => transfers.isEmpty
            ? const Center(child: Text('No stock transfers recorded.'))
            : ListView.separated(
                itemCount: transfers.length,
                separatorBuilder: (context, _) => const Divider(),
                itemBuilder: (context, index) {
                  final t = transfers[index];
                  return ListTile(
                    leading: const Icon(Icons.local_shipping),
                    title: Text('Transfer #${t.id}'),
                    subtitle: Text('Status: ${t.status} | Date: ${DateFormat('dd MMM').format(t.transferDate)}'),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
