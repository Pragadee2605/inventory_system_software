import 'package:inventory_system_software/features/inventory/domain/models/stock_transaction.dart';

abstract class InventoryRepository {
  Future<List<StockTransaction>> getTransactionHistory({int? productId, int limit = 100});
  
  Future<void> recordTransaction({
    required int productId,
    required StockTransactionType type,
    required int quantity,
    required int userId,
    String? reason,
  });

  Future<int> getTotalStockValue();
}
