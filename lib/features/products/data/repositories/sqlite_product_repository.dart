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
    final cleanSku = sku.trim();
    final cleanName = name.trim();
    final cleanBarcode = barcode?.trim();

    if (cleanSku.isEmpty) throw Exception('Product SKU is required.');
    if (cleanName.isEmpty) throw Exception('Product Name is required.');
    if (purchasePrice < 0 || sellingPrice < 0) {
      throw Exception('Purchase and Selling prices cannot be negative.');
    }
    if (currentStock < 0) {
      throw Exception('Initial stock cannot be negative.');
    }

    // Check SKU Uniqueness
    final existingSku = await (_db.select(_db.products)..where((t) => t.sku.equals(cleanSku))).getSingleOrNull();
    if (existingSku != null) {
      throw Exception('Product with SKU "$cleanSku" already exists.');
    }

    // Check Barcode Uniqueness if provided
    if (cleanBarcode != null && cleanBarcode.isNotEmpty) {
      final existingBarcode = await (_db.select(_db.products)..where((t) => t.barcode.equals(cleanBarcode))).getSingleOrNull();
      if (existingBarcode != null) {
        throw Exception('Product with barcode "$cleanBarcode" already exists.');
      }
    }

    final id = await _db.into(_db.products).insert(
      ProductsCompanion.insert(
        sku: cleanSku,
        barcode: Value(cleanBarcode),
        name: cleanName,
        categoryId: categoryId,
        brandId: Value(brandId),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        currentStock: Value(currentStock),
        minStock: Value(minStock),
      ),
    );

    return id;
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
    final cleanSku = sku.trim();
    final cleanName = name.trim();
    final cleanBarcode = barcode?.trim();

    if (cleanSku.isEmpty) throw Exception('Product SKU is required.');
    if (cleanName.isEmpty) throw Exception('Product Name is required.');
    if (purchasePrice < 0 || sellingPrice < 0) {
      throw Exception('Purchase and Selling prices cannot be negative.');
    }

    // Check SKU Uniqueness for other products
    final existingSku = await (_db.select(_db.products)
          ..where((t) => t.sku.equals(cleanSku) & t.id.equals(id).not()))
        .getSingleOrNull();
    if (existingSku != null) {
      throw Exception('Another product with SKU "$cleanSku" already exists.');
    }

    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        sku: Value(cleanSku),
        barcode: Value(cleanBarcode),
        name: Value(cleanName),
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
    // Check if product is referenced in sales or purchases
    final salesCount = await (_db.selectOnly(_db.salesItems)
          ..addColumns([_db.salesItems.id.count()])
          ..where(_db.salesItems.productId.equals(id)))
        .map((row) => row.read(_db.salesItems.id.count()))
        .getSingle();

    if ((salesCount ?? 0) > 0) {
      throw Exception('Cannot delete product: referenced in $salesCount sales order line(s).');
    }

    await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> updateStock(int id, int quantityChange) async {
    final product = await getProductById(id);
    if (product == null) throw Exception('Product ID $id not found.');

    final newStock = product.currentStock + quantityChange;
    if (newStock < 0) {
      throw Exception('Stock cannot be reduced below zero. Current stock: ${product.currentStock}, Change requested: $quantityChange');
    }

    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        currentStock: Value(newStock),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
