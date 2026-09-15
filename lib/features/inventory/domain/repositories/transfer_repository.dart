import 'package:inventory_system_software/core/database/database.dart';

abstract class TransferRepository {
  Future<List<StockTransfer>> getAllTransfers();
  Future<int> createTransfer({
    required int fromLocationId,
    required int toLocationId,
    required List<TransferItemDraft> items,
    required int userId,
  });
  Future<void> completeTransfer(int transferId, int userId);
}

class TransferItemDraft {
  final int productId;
  final int quantity;

  TransferItemDraft({required this.productId, required this.quantity});
}
