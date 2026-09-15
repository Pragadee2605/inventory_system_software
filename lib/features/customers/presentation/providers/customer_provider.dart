import 'package:inventory_system_software/core/database/database.dart' hide Customer;
import 'package:inventory_system_software/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:inventory_system_software/features/customers/domain/models/customer.dart';
import 'package:inventory_system_software/features/customers/domain/repositories/customer_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'customer_provider.g.dart';

@riverpod
CustomerRepository customerRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SqliteCustomerRepository(db);
}

@riverpod
class CustomerList extends _$CustomerList {
  @override
  FutureOr<List<Customer>> build() async {
    return ref.watch(customerRepositoryProvider).getAllCustomers();
  }

  Future<void> addCustomer({required String name, String? email, String? phone}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(customerRepositoryProvider).createCustomer(
        name: name,
        email: email,
        phone: phone,
      );
      return ref.read(customerRepositoryProvider).getAllCustomers();
    });
  }

  Future<void> updateCustomer({required int id, required String name, String? email, String? phone}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(customerRepositoryProvider).updateCustomer(
        id: id,
        name: name,
        email: email,
        phone: phone,
      );
      return ref.read(customerRepositoryProvider).getAllCustomers();
    });
  }

  Future<void> deleteCustomer(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(customerRepositoryProvider).deleteCustomer(id);
      return ref.read(customerRepositoryProvider).getAllCustomers();
    });
  }
}
