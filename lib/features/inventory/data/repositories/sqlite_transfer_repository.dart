import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/inventory/domain/repositories/transfer_repository.dart';

class SqliteTransferRepository implements TransferRepository {
  final AppDatabase _db;

  SqliteTransferRepository(this._db);

  @override
  Future<List<StockTransfer>> getAllTransfers() async {
    return await _db.select(_db.stockTransfers).get();
  }

  @override
  Future<int> createTransfer({
    required int fromLocationId,
    required int toLocationId,
    required List<TransferItemDraft> items,
    required int userId,
  }) async {
    return await _db.transaction(() async {
      final transferId = await _db.into(_db.stockTransfers).insert(
        StockTransfersCompanion.insert(
          fromLocationId: fromLocationId,
          toLocationId: toLocationId,
          status: 'PENDING',
          createdBy: userId,
        ),
      );

      for (final item in items) {
        await _db.into(_db.stockTransferItems).insert(
          StockTransferItemsCompanion.insert(
            transferId: transferId,
            productId: item.productId,
            quantity: item.quantity,
          ),
        );
      }
      return transferId;
    });
  }

  @override
  Future<void> completeTransfer(int transferId, int userId) async {
    await _db.transaction(() async {
      final items = await (_db.select(_db.stockTransferItems)..where((t) => t.transferId.equals(transferId))).get();
      
      for (final item in items) {
        // Record Stock Transactions for tracking
        // TRANSFER_OUT from Location A, TRANSFER_IN to Location B
        // Note: Global stock might not change if we are tracking total across all locations,
        // but typically transfers move between managed sub-inventories.
        
        await _db.into(_db.stockTransactions).insert(
          StockTransactionsCompanion.insert(
            productId: item.productId,
            type: 'TRANSFER',
            quantity: item.quantity,
            previousStock: 0, // Simplified for v1
            newStock: 0,
            userId: userId,
            reason: Value('Transfer #$transferId'),
          ),
        );
      }

      await (_db.update(_db.stockTransfers)..where((t) => t.id.equals(transferId))).write(
        const StockTransfersCompanion(status: Value('COMPLETED')),
      );
    });
  }
}
