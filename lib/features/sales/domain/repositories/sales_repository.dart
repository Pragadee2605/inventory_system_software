import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart';

abstract class SalesRepository {
  Future<List<SalesOrder>> getAllSales();
  Future<SalesOrder?> getSaleById(int id);
  Future<int> createSale({
    int? customerId,
    required List<SalesItemDraft> items,
    required int userId,
  });
}

class SalesItemDraft {
  final int productId;
  final int quantity;
  final double unitPrice;

  SalesItemDraft({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });
}
