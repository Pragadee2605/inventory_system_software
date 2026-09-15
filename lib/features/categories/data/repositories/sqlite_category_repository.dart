import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/categories/domain/models/category.dart' as model;
import 'package:inventory_system_software/features/categories/domain/repositories/category_repository.dart';

class SqliteCategoryRepository implements CategoryRepository {
  final AppDatabase _db;

  SqliteCategoryRepository(this._db);

  @override
  Future<List<model.Category>> getAllCategories() async {
    final rows = await _db.select(_db.categories).get();
    return rows.map((row) => model.Category(
      id: row.id,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
    )).toList();
  }

  @override
  Future<model.Category?> getCategoryById(int id) async {
    final row = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return model.Category(
      id: row.id,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<int> createCategory(String name, String? description) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Category name is required.');

    final existing = await (_db.select(_db.categories)..where((t) => t.name.equals(cleanName))).getSingleOrNull();
    if (existing != null) {
      throw Exception('Category "$cleanName" already exists.');
    }

    return await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        name: cleanName,
        description: Value(description?.trim()),
      ),
    );
  }

  @override
  Future<void> updateCategory(int id, String name, String? description) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Category name is required.');

    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(cleanName),
        description: Value(description?.trim()),
      ),
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    // Check if category is referenced by products
    final countExp = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([countExp])
      ..where(_db.products.categoryId.equals(id));
    
    final count = await query.map((row) => row.read(countExp)).getSingle();
    if ((count ?? 0) > 0) {
      throw Exception('Cannot delete category: it is assigned to $count product(s). Please reassign or delete those products first.');
    }

    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }
}
