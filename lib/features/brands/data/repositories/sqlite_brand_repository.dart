import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/brands/domain/models/brand.dart' as model;
import 'package:inventory_system_software/features/brands/domain/repositories/brand_repository.dart';

class SqliteBrandRepository implements BrandRepository {
  final AppDatabase _db;

  SqliteBrandRepository(this._db);

  @override
  Future<List<model.Brand>> getAllBrands() async {
    final rows = await _db.select(_db.brands).get();
    return rows.map((row) => model.Brand(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
    )).toList();
  }

  @override
  Future<model.Brand?> getBrandById(int id) async {
    final row = await (_db.select(_db.brands)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return model.Brand(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<int> createBrand(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Brand name is required.');

    final existing = await (_db.select(_db.brands)..where((t) => t.name.equals(cleanName))).getSingleOrNull();
    if (existing != null) {
      throw Exception('Brand "$cleanName" already exists.');
    }

    return await _db.into(_db.brands).insert(
      BrandsCompanion.insert(name: cleanName),
    );
  }

  @override
  Future<void> updateBrand(int id, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Brand name is required.');

    await (_db.update(_db.brands)..where((t) => t.id.equals(id))).write(
      BrandsCompanion(name: Value(cleanName)),
    );
  }

  @override
  Future<void> deleteBrand(int id) async {
    // Check if brand is referenced by products
    final countExp = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([countExp])
      ..where(_db.products.brandId.equals(id));
    
    final count = await query.map((row) => row.read(countExp)).getSingle();
    if ((count ?? 0) > 0) {
      throw Exception('Cannot delete brand: it is assigned to $count product(s).');
    }

    await (_db.delete(_db.brands)..where((t) => t.id.equals(id))).go();
  }
}
