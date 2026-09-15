import 'package:inventory_system_software/features/products/domain/models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(int id);
  Future<Product?> getProductByBarcode(String barcode);
  Future<int> createProduct({
    required String sku,
    String? barcode,
    required String name,
    required int categoryId,
    int? brandId,
    double purchasePrice = 0.0,
    double sellingPrice = 0.0,
    int currentStock = 0,
    int minStock = 5,
  });
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
  });
  Future<void> deleteProduct(int id);
  Future<void> updateStock(int id, int quantityChange);
}
