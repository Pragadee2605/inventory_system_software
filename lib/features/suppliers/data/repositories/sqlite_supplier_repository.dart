import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/suppliers/domain/models/supplier.dart' as model;
import 'package:inventory_system_software/features/suppliers/domain/repositories/supplier_repository.dart';

class SqliteSupplierRepository implements SupplierRepository {
  final AppDatabase _db;

  SqliteSupplierRepository(this._db);

  @override
  Future<List<model.Supplier>> getAllSuppliers() async {
    final rows = await _db.select(_db.suppliers).get();
    return rows.map((row) => model.Supplier(
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      address: row.address,
      createdAt: row.createdAt,
    )).toList();
  }

  @override
  Future<model.Supplier?> getSupplierById(int id) async {
    final row = await (_db.select(_db.suppliers)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return model.Supplier(
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      address: row.address,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<int> createSupplier({required String name, String? email, String? phone, String? address}) async {
    return await _db.into(_db.suppliers).insert(
      SuppliersCompanion.insert(
        name: name,
        email: Value(email),
        phone: Value(phone),
        address: Value(address),
      ),
    );
  }

  @override
  Future<void> updateSupplier({required int id, required String name, String? email, String? phone, String? address}) async {
    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        name: Value(name),
        email: Value(email),
        phone: Value(phone),
        address: Value(address),
      ),
    );
  }

  @override
  Future<void> deleteSupplier(int id) async {
    await (_db.delete(_db.suppliers)..where((t) => t.id.equals(id))).go();
  }
}
