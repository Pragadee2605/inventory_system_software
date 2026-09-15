import 'package:inventory_system_software/features/customers/domain/models/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getAllCustomers();
  Future<Customer?> getCustomerById(int id);
  Future<int> createCustomer({required String name, String? email, String? phone});
  Future<void> updateCustomer({required int id, required String name, String? email, String? phone});
  Future<void> deleteCustomer(int id);
}
