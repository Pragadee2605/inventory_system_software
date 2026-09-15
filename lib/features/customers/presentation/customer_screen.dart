import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/customers/presentation/providers/customer_provider.dart';
import 'package:inventory_system_software/features/customers/domain/models/customer.dart';

class CustomerScreen extends ConsumerWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCustomerDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Customer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: customersAsync.when(
        data: (customers) => customers.isEmpty
            ? const Center(child: Text('No customers found.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        title: Text(customer.name),
                        subtitle: Text(customer.phone ?? customer.email ?? 'No contact info'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showCustomerDialog(context, ref, customer: customer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, customer),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, WidgetRef ref, {Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final emailController = TextEditingController(text: customer?.email);
    final phoneController = TextEditingController(text: customer?.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (customer == null) {
                  ref.read(customerListProvider.notifier).addCustomer(
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                      );
                } else {
                  ref.read(customerListProvider.notifier).updateCustomer(
                        id: customer.id,
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                      );
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(customerListProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
