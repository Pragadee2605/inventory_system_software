import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/customers/domain/models/customer.dart' as model;
import 'package:inventory_system_software/features/customers/domain/repositories/customer_repository.dart';

class SqliteCustomerRepository implements CustomerRepository {
  final AppDatabase _db;

  SqliteCustomerRepository(this._db);

  @override
  Future<List<model.Customer>> getAllCustomers() async {
    final rows = await _db.select(_db.customers).get();
    return rows.map((row) => model.Customer(
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      createdAt: row.createdAt,
    )).toList();
  }

  @override
  Future<model.Customer?> getCustomerById(int id) async {
    final row = await (_db.select(_db.customers)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return model.Customer(
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<int> createCustomer({required String name, String? email, String? phone}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Customer name is required.');

    return await _db.into(_db.customers).insert(
      CustomersCompanion.insert(
        name: cleanName,
        email: Value(email?.trim()),
        phone: Value(phone?.trim()),
      ),
    );
  }

  @override
  Future<void> updateCustomer({required int id, required String name, String? email, String? phone}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Customer name is required.');

    await (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        name: Value(cleanName),
        email: Value(email?.trim()),
        phone: Value(phone?.trim()),
      ),
    );
  }

  @override
  Future<void> deleteCustomer(int id) async {
    // Check if customer is referenced in sales orders
    final countExp = _db.salesOrders.id.count();
    final query = _db.selectOnly(_db.salesOrders)
      ..addColumns([countExp])
      ..where(_db.salesOrders.customerId.equals(id));
    
    final count = await query.map((row) => row.read(countExp)).getSingle();
    if ((count ?? 0) > 0) {
      throw Exception('Cannot delete customer: referenced in $count sales order(s).');
    }

    await (_db.delete(_db.customers)..where((t) => t.id.equals(id))).go();
  }
}
