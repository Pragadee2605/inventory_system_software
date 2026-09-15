import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart' as model;
import 'package:inventory_system_software/features/products/domain/repositories/product_repository.dart';

class SqliteProductRepository implements ProductRepository {
  final AppDatabase _db;

  SqliteProductRepository(this._db);

  @override
  Future<List<model.Product>> getAllProducts() async {
    final query = _db.select(_db.products).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
      leftOuterJoin(_db.brands, _db.brands.id.equalsExp(_db.products.brandId)),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final product = row.readTable(_db.products);
      final category = row.readTable(_db.categories);
      final brand = row.readTableOrNull(_db.brands);

      return model.Product(
        id: product.id,
        sku: product.sku,
        barcode: product.barcode,
        name: product.name,
        categoryId: product.categoryId,
        categoryName: category.name,
        brandId: product.brandId,
        brandName: brand?.name,
        purchasePrice: product.purchasePrice,
        sellingPrice: product.sellingPrice,
        currentStock: product.currentStock,
        minStock: product.minStock,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
    }).toList();
  }

  @override
  Future<model.Product?> getProductById(int id) async {
    final query = _db.select(_db.products).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
      leftOuterJoin(_db.brands, _db.brands.id.equalsExp(_db.products.brandId)),
    ])..where(_db.products.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final product = row.readTable(_db.products);
    final category = row.readTable(_db.categories);
    final brand = row.readTableOrNull(_db.brands);

    return model.Product(
      id: product.id,
      sku: product.sku,
      barcode: product.barcode,
      name: product.name,
      categoryId: product.categoryId,
      categoryName: category.name,
      brandId: product.brandId,
      brandName: brand?.name,
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
      currentStock: product.currentStock,
      minStock: product.minStock,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  @override
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
  }) async {
    return await _db.into(_db.products).insert(
      ProductsCompanion.insert(
        sku: sku,
        barcode: Value(barcode),
        name: name,
        categoryId: categoryId,
        brandId: Value(brandId),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        currentStock: Value(currentStock),
        minStock: Value(minStock),
      ),
    );
  }

  @override
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
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        sku: Value(sku),
        barcode: Value(barcode),
        name: Value(name),
        categoryId: Value(categoryId),
        brandId: Value(brandId),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        minStock: Value(minStock),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> updateStock(int id, int quantityChange) async {
    final product = await getProductById(id);
    if (product == null) return;

    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        currentStock: Value(product.currentStock + quantityChange),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
