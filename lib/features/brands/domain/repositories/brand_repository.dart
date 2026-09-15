import 'package:inventory_system_software/features/brands/domain/models/brand.dart';

abstract class BrandRepository {
  Future<List<Brand>> getAllBrands();
  Future<Brand?> getBrandById(int id);
  Future<int> createBrand(String name);
  Future<void> updateBrand(int id, String name);
  Future<void> deleteBrand(int id);
}
