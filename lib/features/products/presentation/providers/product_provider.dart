import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/core/database/database.dart' hide Product;
import 'package:inventory_system_software/features/products/data/repositories/sqlite_product_repository.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart';
import 'package:inventory_system_software/features/products/domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SqliteProductRepository(db);
});

final productListProvider = AsyncNotifierProvider<ProductList, List<Product>>(ProductList.new);

class ProductList extends AsyncNotifier<List<Product>> {
  @override
  FutureOr<List<Product>> build() async {
    return ref.watch(productRepositoryProvider).getAllProducts();
  }

  Future<void> addProduct({
    required String sku,
    String? barcode,
    required String name,
    required int categoryId,
    int? brandId,
    double purchasePrice = 0.0,
    double sellingPrice = 0.0,
    int currentStock = 0,
    int minStock = 5,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).createProduct(
        sku: sku,
        barcode: barcode,
        name: name,
        categoryId: categoryId,
        brandId: brandId,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        currentStock: currentStock,
        minStock: minStock,
      );
      return ref.read(productRepositoryProvider).getAllProducts();
    });
  }

  Future<void> updateProduct({
    required int id,
    required String sku,
    String? barcode,
    required String name,
    required int categoryId,
    int? brandId,
    required double purchasePrice,
    required double sellingPrice,
    required int minStock,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).updateProduct(
        id: id,
        sku: sku,
        barcode: barcode,
        name: name,
        categoryId: categoryId,
        brandId: brandId,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        minStock: minStock,
      );
      return ref.read(productRepositoryProvider).getAllProducts();
    });
  }

  Future<void> deleteProduct(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).deleteProduct(id);
      return ref.read(productRepositoryProvider).getAllProducts();
    });
  }
}
