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
    return await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        name: name,
        description: Value(description),
      ),
    );
  }

  @override
  Future<void> updateCategory(int id, String name, String? description) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        description: Value(description),
      ),
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    // Note: In production, check for products first or use soft delete.
    // For now, physical delete as requested if no transactions exist.
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }
}
