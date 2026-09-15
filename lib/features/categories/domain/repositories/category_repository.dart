import 'package:inventory_system_software/features/categories/domain/models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(int id);
  Future<int> createCategory(String name, String? description);
  Future<void> updateCategory(int id, String name, String? description);
  Future<void> deleteCategory(int id);
}
