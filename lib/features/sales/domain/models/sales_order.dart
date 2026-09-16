class SalesOrder {
  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime saleDate;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final double profitAmount;
  final String status;
  final int createdBy;
  final List<SalesItem> items;

  SalesOrder({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.saleDate,
    required this.totalAmount,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.profitAmount = 0.0,
    this.status = 'COMPLETED',
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
  final double purchasePrice; // Cost price at time of sale
  final double subtotal;

  SalesItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.purchasePrice = 0.0,
    required this.subtotal,
  });
}
