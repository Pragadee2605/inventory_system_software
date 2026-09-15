class PurchaseOrder {
  final int id;
  final String orderNumber;
  final int supplierId;
  final String supplierName;
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final int createdBy;
  final List<PurchaseItem> items;

  PurchaseOrder({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.supplierName,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.createdBy,
    this.items = const [],
  });
}

class PurchaseItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final int receivedQuantity;
  final double unitPrice;

  PurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.receivedQuantity,
    required this.unitPrice,
  });
}
