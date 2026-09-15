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
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Supplier name is required.');

    return await _db.into(_db.suppliers).insert(
      SuppliersCompanion.insert(
        name: cleanName,
        email: Value(email?.trim()),
        phone: Value(phone?.trim()),
        address: Value(address?.trim()),
      ),
    );
  }

  @override
  Future<void> updateSupplier({required int id, required String name, String? email, String? phone, String? address}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Supplier name is required.');

    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        name: Value(cleanName),
        email: Value(email?.trim()),
        phone: Value(phone?.trim()),
        address: Value(address?.trim()),
      ),
    );
  }

  @override
  Future<void> deleteSupplier(int id) async {
    // Check if supplier is referenced in purchase orders
    final countExp = _db.purchaseOrders.id.count();
    final query = _db.selectOnly(_db.purchaseOrders)
      ..addColumns([countExp])
      ..where(_db.purchaseOrders.supplierId.equals(id));
    
    final count = await query.map((row) => row.read(countExp)).getSingle();
    if ((count ?? 0) > 0) {
      throw Exception('Cannot delete supplier: referenced in $count purchase order(s).');
    }

    await (_db.delete(_db.suppliers)..where((t) => t.id.equals(id))).go();
  }
}
