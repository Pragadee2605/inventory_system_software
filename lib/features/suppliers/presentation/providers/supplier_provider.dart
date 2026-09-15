import 'package:inventory_system_software/core/database/database.dart' hide Supplier;
import 'package:inventory_system_software/features/suppliers/data/repositories/sqlite_supplier_repository.dart';
import 'package:inventory_system_software/features/suppliers/domain/models/supplier.dart';
import 'package:inventory_system_software/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supplier_provider.g.dart';

@riverpod
SupplierRepository supplierRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SqliteSupplierRepository(db);
}

@riverpod
class SupplierList extends _$SupplierList {
  @override
  FutureOr<List<Supplier>> build() async {
    return ref.watch(supplierRepositoryProvider).getAllSuppliers();
  }

  Future<void> addSupplier({required String name, String? email, String? phone, String? address}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(supplierRepositoryProvider).createSupplier(
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      return ref.read(supplierRepositoryProvider).getAllSuppliers();
    });
  }

  Future<void> updateSupplier({required int id, required String name, String? email, String? phone, String? address}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(supplierRepositoryProvider).updateSupplier(
        id: id,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      return ref.read(supplierRepositoryProvider).getAllSuppliers();
    });
  }

  Future<void> deleteSupplier(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(supplierRepositoryProvider).deleteSupplier(id);
      return ref.read(supplierRepositoryProvider).getAllSuppliers();
    });
  }
}
