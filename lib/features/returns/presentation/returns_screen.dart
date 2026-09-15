import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/features/returns/data/repositories/sqlite_return_repository.dart';
import 'package:inventory_system_software/core/database/database.dart';

final returnRepositoryProvider = Provider((ref) => SqliteReturnRepository(ref.watch(databaseProvider)));
final returnListProvider = FutureProvider((ref) => ref.watch(returnRepositoryProvider).getAllReturns());

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(returnListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Returns Management')),
      body: returnsAsync.when(
        data: (returns) => returns.isEmpty
            ? const Center(child: Text('No returns recorded yet.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: returns.length,
                    separatorBuilder: (context, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final ret = returns[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ret.referenceType == 'SALE' ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(
                            ret.referenceType == 'SALE' ? Icons.call_received : Icons.call_made,
                            color: ret.referenceType == 'SALE' ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text('Return #${ret.id} (${ret.referenceType})'),
                        subtitle: Text('Reason: ${ret.reason ?? "N/A"}'),
                        trailing: Text(DateFormat('dd MMM yyyy').format(ret.returnDate)),
                      );
                    },
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
