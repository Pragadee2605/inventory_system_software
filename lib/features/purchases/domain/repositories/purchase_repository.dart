import 'package:inventory_system_software/features/purchases/domain/models/purchase_order.dart';

abstract class PurchaseRepository {
  Future<List<PurchaseOrder>> getAllPurchases();
  Future<PurchaseOrder?> getPurchaseById(int id);
  Future<int> createPurchase({
    required int supplierId,
    required List<PurchaseItemDraft> items,
    required int userId,
  });
  Future<void> receiveItems(int orderId, Map<int, int> receivedQuantities, int userId);
}

class PurchaseItemDraft {
  final int productId;
  final int quantity;
  final double unitPrice;

  PurchaseItemDraft({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });
}
