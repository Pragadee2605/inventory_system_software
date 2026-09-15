import 'package:inventory_system_software/core/database/database.dart' hide Category;
import 'package:inventory_system_software/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:inventory_system_software/features/categories/domain/models/category.dart';
import 'package:inventory_system_software/features/categories/domain/repositories/category_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_provider.g.dart';

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SqliteCategoryRepository(db);
}

@riverpod
class CategoryList extends _$CategoryList {
  @override
  FutureOr<List<Category>> build() async {
    return ref.watch(categoryRepositoryProvider).getAllCategories();
  }

  Future<void> addCategory(String name, String? description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).createCategory(name, description);
      return ref.read(categoryRepositoryProvider).getAllCategories();
    });
  }

  Future<void> updateCategory(int id, String name, String? description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).updateCategory(id, name, description);
      return ref.read(categoryRepositoryProvider).getAllCategories();
    });
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).deleteCategory(id);
      return ref.read(categoryRepositoryProvider).getAllCategories();
    });
  }
}
