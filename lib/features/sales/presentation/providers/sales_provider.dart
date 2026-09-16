import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/core/database/database.dart' hide SalesOrder, SalesItem;
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';
import 'package:inventory_system_software/features/sales/data/repositories/sqlite_sales_repository.dart';
import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart';
import 'package:inventory_system_software/features/sales/domain/repositories/sales_repository.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/inventory/presentation/providers/inventory_provider.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SqliteSalesRepository(db);
});

final salesListProvider = AsyncNotifierProvider<SalesList, List<SalesOrder>>(SalesList.new);

class SalesList extends AsyncNotifier<List<SalesOrder>> {
  @override
  FutureOr<List<SalesOrder>> build() async {
    return ref.watch(salesRepositoryProvider).getAllSales(status: 'COMPLETED');
  }

  Future<int?> createSale({
    int? customerId,
    required List<SalesItemDraft> items,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    String status = 'COMPLETED',
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return null;

    int? orderId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      orderId = await ref.read(salesRepositoryProvider).createSale(
        customerId: customerId,
        items: items,
        userId: user.id,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        status: status,
      );
      
      if (status == 'COMPLETED') {
        ref.invalidate(productListProvider);
        ref.invalidate(stockTransactionListProvider);
      }
      
      ref.invalidate(heldSalesProvider);
      return ref.read(salesRepositoryProvider).getAllSales(status: 'COMPLETED');
    });
    return orderId;
  }

  Future<void> completeHeldSale(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(salesRepositoryProvider).updateSaleStatus(id, 'COMPLETED');
      ref.invalidate(productListProvider);
      ref.invalidate(stockTransactionListProvider);
      ref.invalidate(heldSalesProvider);
      return ref.read(salesRepositoryProvider).getAllSales(status: 'COMPLETED');
    });
  }
}

final heldSalesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesRepositoryProvider).getAllSales(status: 'HOLD');
});

final salesTotalProfitProvider = FutureProvider<double>((ref) async {
  final sales = await ref.watch(salesRepositoryProvider).getAllSales(status: 'COMPLETED');
  return sales.fold<double>(0.0, (double sum, s) => sum + s.profitAmount);
});
