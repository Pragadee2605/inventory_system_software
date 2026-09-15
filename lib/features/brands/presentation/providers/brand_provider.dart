import 'package:inventory_system_software/core/database/database.dart' hide Brand;
import 'package:inventory_system_software/features/brands/data/repositories/sqlite_brand_repository.dart';
import 'package:inventory_system_software/features/brands/domain/models/brand.dart';
import 'package:inventory_system_software/features/brands/domain/repositories/brand_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'brand_provider.g.dart';

@riverpod
BrandRepository brandRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SqliteBrandRepository(db);
}

@riverpod
class BrandList extends _$BrandList {
  @override
  FutureOr<List<Brand>> build() async {
    return ref.watch(brandRepositoryProvider).getAllBrands();
  }

  Future<void> addBrand(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(brandRepositoryProvider).createBrand(name);
      return ref.read(brandRepositoryProvider).getAllBrands();
    });
  }

  Future<void> updateBrand(int id, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(brandRepositoryProvider).updateBrand(id, name);
      return ref.read(brandRepositoryProvider).getAllBrands();
    });
  }

  Future<void> deleteBrand(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(brandRepositoryProvider).deleteBrand(id);
      return ref.read(brandRepositoryProvider).getAllBrands();
    });
  }
}
