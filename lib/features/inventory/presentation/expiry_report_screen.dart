import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/core/database/database.dart';

final expiringBatchesProvider = FutureProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.productBatches).join([
    innerJoin(db.products, db.products.id.equalsExp(db.productBatches.productId)),
  ])..where(db.productBatches.expiryDate.isNotNull()))
    .get();
});

class ExpiryReportScreen extends ConsumerWidget {
  const ExpiryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(expiringBatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expiry Tracking')),
      body: batchesAsync.when(
        data: (rows) => rows.isEmpty
            ? const Center(child: Text('No batches with expiry dates found.'))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final batch = rows[index].readTable(ref.read(databaseProvider).productBatches);
                  final product = rows[index].readTable(ref.read(databaseProvider).products);
                  final isExpired = batch.expiryDate != null && batch.expiryDate!.isBefore(DateTime.now());

                  return ListTile(
                    leading: Icon(Icons.inventory, color: isExpired ? Colors.red : Colors.green),
                    title: Text('${product.name} (Batch: ${batch.batchNumber})'),
                    subtitle: Text('Expiry: ${batch.expiryDate != null ? DateFormat('dd MMM yyyy').format(batch.expiryDate!) : "N/A"}'),
                    trailing: Text('Stock: ${batch.currentStock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
