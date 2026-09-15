import 'package:inventory_system_software/features/suppliers/domain/models/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getAllSuppliers();
  Future<Supplier?> getSupplierById(int id);
  Future<int> createSupplier({required String name, String? email, String? phone, String? address});
  Future<void> updateSupplier({required int id, required String name, String? email, String? phone, String? address});
  Future<void> deleteSupplier(int id);
}
