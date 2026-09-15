class SalesOrder {
  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final DateTime saleDate;
  final double totalAmount;
  final int createdBy;
  final List<SalesItem> items;

  SalesOrder({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.saleDate,
    required this.totalAmount,
    required this.createdBy,
    this.items = const [],
  });
}

class SalesItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SalesItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}
