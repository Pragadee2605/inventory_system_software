class ReturnOrder {
  final int id;
  final String referenceType;
  final int referenceId;
  final DateTime returnDate;
  final String? reason;
  final List<ReturnItem> items;

  ReturnOrder({
    required this.id,
    required this.referenceType,
    required this.referenceId,
    required this.returnDate,
    this.reason,
    this.items = const [],
  });
}

class ReturnItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;

  ReturnItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}
