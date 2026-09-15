import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/inventory/domain/models/stock_transaction.dart' as model;
import 'package:inventory_system_software/features/inventory/domain/repositories/inventory_repository.dart';

class SqliteInventoryRepository implements InventoryRepository {
  final AppDatabase _db;

  SqliteInventoryRepository(this._db);

  @override
  Future<List<model.StockTransaction>> getTransactionHistory({int? productId, int limit = 100}) async {
    final query = _db.select(_db.stockTransactions).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.stockTransactions.productId)),
      innerJoin(_db.users, _db.users.id.equalsExp(_db.stockTransactions.userId)),
    ]);

    if (productId != null) {
      query.where(_db.stockTransactions.productId.equals(productId));
    }

    query.orderBy([OrderingTerm.desc(_db.stockTransactions.createdAt)]);
    query.limit(limit);

    final rows = await query.get();
    return rows.map((row) {
      final trans = row.readTable(_db.stockTransactions);
      final product = row.readTable(_db.products);
      final user = row.readTable(_db.users);

      return model.StockTransaction(
        id: trans.id,
        productId: trans.productId,
        productName: product.name,
        sku: product.sku,
        type: model.StockTransactionTypeExtension.fromString(trans.type),
        quantity: trans.quantity,
        previousStock: trans.previousStock,
        newStock: trans.newStock,
        createdAt: trans.createdAt,
        userId: trans.userId,
        userName: user.fullName,
        reason: trans.reason,
      );
    }).toList();
  }

  @override
  Future<void> recordTransaction({
    required int productId,
    required model.StockTransactionType type,
    required int quantity,
    required int userId,
    String? reason,
  }) async {
    await _db.transaction(() async {
      // 1. Get current product stock
      final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingle();
      
      final previousStock = product.currentStock;
      int newStock = previousStock;

      // Calculate new stock based on type
      switch (type) {
        case model.StockTransactionType.stockIn:
        case model.StockTransactionType.purchase:
        case model.StockTransactionType.returnIn:
          newStock += quantity;
          break;
        case model.StockTransactionType.stockOut:
        case model.StockTransactionType.sale:
        case model.StockTransactionType.damage:
        case model.StockTransactionType.returnOut:
          newStock -= quantity;
          break;
        case model.StockTransactionType.adjustment:
          // For adjustment, 'quantity' could be absolute or relative. 
          // Here we treat it as relative (+/-)
          newStock += quantity;
          break;
      }

      // 2. Update product stock
      await (_db.update(_db.products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          currentStock: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 3. Record transaction
      await _db.into(_db.stockTransactions).insert(
        StockTransactionsCompanion.insert(
          productId: productId,
          type: type.value,
          quantity: quantity,
          previousStock: previousStock,
          newStock: newStock,
          userId: userId,
          reason: Value(reason),
        ),
      );
    });
  }

  @override
  Future<int> getTotalStockValue() async {
    final query = _db.selectOnly(_db.products)..addColumns([_db.products.currentStock, _db.products.purchasePrice]);
    final rows = await query.get();
    
    double total = 0;
    for (final row in rows) {
      final stock = row.read(_db.products.currentStock) ?? 0;
      final price = row.read(_db.products.purchasePrice) ?? 0.0;
      total += stock * price;
    }
    return total.toInt();
  }
}
