import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/core/database/database.dart' hide StockTransaction;
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';
import 'package:inventory_system_software/features/inventory/data/repositories/sqlite_inventory_repository.dart';
import 'package:inventory_system_software/features/inventory/domain/models/stock_transaction.dart';
import 'package:inventory_system_software/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SqliteInventoryRepository(db);
});

final stockTransactionListProvider = AsyncNotifierProvider<StockTransactionList, List<StockTransaction>>(StockTransactionList.new);

class StockTransactionList extends AsyncNotifier<List<StockTransaction>> {
  @override
  FutureOr<List<StockTransaction>> build() async {
    return ref.watch(inventoryRepositoryProvider).getTransactionHistory();
  }

  Future<void> addTransaction({
    required int productId,
    required StockTransactionType type,
    required int quantity,
    String? reason,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).recordTransaction(
        productId: productId,
        type: type,
        quantity: quantity,
        userId: user.id,
        reason: reason,
      );
      ref.invalidate(productListProvider);
      return ref.read(inventoryRepositoryProvider).getTransactionHistory();
    });
  }
}
