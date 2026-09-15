import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/core/database/database.dart' hide Brand;
import 'package:inventory_system_software/features/brands/data/repositories/sqlite_brand_repository.dart';
import 'package:inventory_system_software/features/brands/domain/models/brand.dart';
import 'package:inventory_system_software/features/brands/domain/repositories/brand_repository.dart';
import 'package:logging/logging.dart';

final _logger = Logger('BrandProvider');

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SqliteBrandRepository(db);
});

final brandListProvider = AsyncNotifierProvider<BrandList, List<Brand>>(BrandList.new);

class BrandList extends AsyncNotifier<List<Brand>> {
  @override
  FutureOr<List<Brand>> build() async {
    final data = await ref.watch(brandRepositoryProvider).getAllBrands();
    _logger.info('Loaded ${data.length} brands');
    return data;
  }

  Future<void> addBrand(String name) async {
    _logger.info('Adding brand: $name');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(brandRepositoryProvider).createBrand(name);
      return ref.read(brandRepositoryProvider).getAllBrands();
    });
  }

  Future<void> updateBrand(int id, String name) async {
    _logger.info('Updating brand id=$id name=$name');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(brandRepositoryProvider).updateBrand(id, name);
      return ref.read(brandRepositoryProvider).getAllBrands();
    });
  }

  Future<void> deleteBrand(int id) async {
    _logger.info('Deleting brand id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(brandRepositoryProvider).deleteBrand(id);
      return ref.read(brandRepositoryProvider).getAllBrands();
    });
  }
}
