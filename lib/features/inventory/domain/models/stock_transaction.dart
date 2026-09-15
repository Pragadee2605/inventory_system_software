enum StockTransactionType {
  stockIn,
  stockOut,
  adjustment,
  damage,
  sale,
  purchase,
  returnIn,
  returnOut
}

extension StockTransactionTypeExtension on StockTransactionType {
  String get value {
    switch (this) {
      case StockTransactionType.stockIn: return 'STOCK_IN';
      case StockTransactionType.stockOut: return 'STOCK_OUT';
      case StockTransactionType.adjustment: return 'ADJUSTMENT';
      case StockTransactionType.damage: return 'DAMAGE';
      case StockTransactionType.sale: return 'SALE';
      case StockTransactionType.purchase: return 'PURCHASE';
      case StockTransactionType.returnIn: return 'RETURN_IN';
      case StockTransactionType.returnOut: return 'RETURN_OUT';
    }
  }

  static StockTransactionType fromString(String value) {
    return StockTransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StockTransactionType.adjustment,
    );
  }
}

class StockTransaction {
  final int id;
  final int productId;
  final String productName;
  final String sku;
  final StockTransactionType type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final DateTime createdAt;
  final int userId;
  final String userName;
  final String? reason;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.createdAt,
    required this.userId,
    required this.userName,
    this.reason,
  });
}
