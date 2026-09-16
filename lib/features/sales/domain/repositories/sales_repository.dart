import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart';

abstract class SalesRepository {
  Future<List<SalesOrder>> getAllSales({String? status});
  Future<SalesOrder?> getSaleById(int id);
  Future<int> createSale({
    int? customerId,
    required List<SalesItemDraft> items,
    required int userId,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    String status = 'COMPLETED',
  });
  Future<void> updateSaleStatus(int id, String status);
}

class SalesItemDraft {
  final int productId;
  final int quantity;
  final double unitPrice;
  final double purchasePrice;

  SalesItemDraft({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.purchasePrice,
  });
}
