import 'package:inventory_system_software/core/database/database.dart' hide PurchaseOrder, PurchaseItem;
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';
import 'package:inventory_system_software/features/purchases/data/repositories/sqlite_purchase_repository.dart';
import 'package:inventory_system_software/features/purchases/domain/models/purchase_order.dart';
import 'package:inventory_system_software/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_provider.g.dart';

@riverpod
PurchaseRepository purchaseRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SqlitePurchaseRepository(db);
}

@riverpod
class PurchaseList extends _$PurchaseList {
  @override
  FutureOr<List<PurchaseOrder>> build() async {
    return ref.watch(purchaseRepositoryProvider).getAllPurchases();
  }

  Future<void> createPurchase({
    required int supplierId,
    required List<PurchaseItemDraft> items,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(purchaseRepositoryProvider).createPurchase(
        supplierId: supplierId,
        items: items,
        userId: user.id,
      );
      return ref.read(purchaseRepositoryProvider).getAllPurchases();
    });
  }

  Future<void> receiveItems(int orderId, Map<int, int> receivedQuantities) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(purchaseRepositoryProvider).receiveItems(orderId, receivedQuantities, user.id);
      ref.invalidate(productListProvider);
      return ref.read(purchaseRepositoryProvider).getAllPurchases();
    });
  }
}

@riverpod
Future<PurchaseOrder?> purchaseDetails(Ref ref, int id) {
  return ref.watch(purchaseRepositoryProvider).getPurchaseById(id);
}
