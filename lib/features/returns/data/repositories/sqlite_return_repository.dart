import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/returns/domain/models/return_order.dart' as model;

class SqliteReturnRepository {
  final AppDatabase _db;

  SqliteReturnRepository(this._db);

  Future<List<model.ReturnOrder>> getAllReturns() async {
    final rows = await _db.select(_db.returns).get();
    return rows.map((r) => model.ReturnOrder(
      id: r.id,
      referenceType: r.referenceType,
      referenceId: r.referenceId,
      returnDate: r.returnDate,
      reason: r.reason,
    )).toList();
  }

  Future<int> createReturn({
    required String type, // SALE or PURCHASE
    required int referenceId,
    required List<model.ReturnItem> items,
    required int userId,
    String? reason,
  }) async {
    return await _db.transaction(() async {
      final returnId = await _db.into(_db.returns).insert(
        ReturnsCompanion.insert(
          referenceType: type,
          referenceId: referenceId,
          reason: Value(reason),
          createdBy: userId,
        ),
      );

      for (final item in items) {
        await _db.into(_db.returnItems).insert(
          ReturnItemsCompanion.insert(
            returnId: returnId,
            productId: item.productId,
            quantity: item.quantity,
          ),
        );

        // Adjust Stock
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingle();
        final prevStock = product.currentStock;
        
        // If SALE return, stock IN. If PURCHASE return, stock OUT.
        int nextStock = type == 'SALE' ? prevStock + item.quantity : prevStock - item.quantity;
        String txType = type == 'SALE' ? 'RETURN_IN' : 'RETURN_OUT';

        await (_db.update(_db.products)..where((t) => t.id.equals(item.productId))).write(
          ProductsCompanion(currentStock: Value(nextStock)),
        );

        await _db.into(_db.stockTransactions).insert(
          StockTransactionsCompanion.insert(
            productId: item.productId,
            type: txType,
            quantity: item.quantity,
            previousStock: prevStock,
            newStock: nextStock,
            userId: userId,
            reason: Value('Return #$returnId'),
          ),
        );
      }
      return returnId;
    });
  }
}
