import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:inventory_system_software/features/suppliers/domain/models/supplier.dart';

class SupplierScreen extends ConsumerWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showSupplierDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Supplier'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: suppliersAsync.when(
        data: (suppliers) => suppliers.isEmpty
            ? const Center(child: Text('No suppliers found.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: suppliers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return ListTile(
                        title: Text(supplier.name),
                        subtitle: Text(supplier.email ?? supplier.phone ?? 'No contact info'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showSupplierDialog(context, ref, supplier: supplier),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, supplier),
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

  void _showSupplierDialog(BuildContext context, WidgetRef ref, {Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name);
    final emailController = TextEditingController(text: supplier?.email);
    final phoneController = TextEditingController(text: supplier?.phone);
    final addressController = TextEditingController(text: supplier?.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
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
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
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
                if (supplier == null) {
                  ref.read(supplierListProvider.notifier).addSupplier(
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        address: addressController.text,
                      );
                } else {
                  ref.read(supplierListProvider.notifier).updateSupplier(
                        id: supplier.id,
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        address: addressController.text,
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete "${supplier.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(supplierListProvider.notifier).deleteSupplier(supplier.id);
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
