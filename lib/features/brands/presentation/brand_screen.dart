import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/brands/presentation/providers/brand_provider.dart';
import 'package:inventory_system_software/features/brands/domain/models/brand.dart';

class BrandScreen extends ConsumerWidget {
  const BrandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showBrandDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Brand'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: brandsAsync.when(
        data: (brands) => brands.isEmpty
            ? const Center(child: Text('No brands found.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: brands.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      return ListTile(
                        title: Text(brand.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showBrandDialog(context, ref, brand: brand),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, brand),
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

  void _showBrandDialog(BuildContext context, WidgetRef ref, {Brand? brand}) {
    final nameController = TextEditingController(text: brand?.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(brand == null ? 'Add Brand' : 'Edit Brand'),
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
                if (brand == null) {
                  ref.read(brandListProvider.notifier).addBrand(nameController.text);
                } else {
                  ref.read(brandListProvider.notifier).updateBrand(brand.id, nameController.text);
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Brand brand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand'),
        content: Text('Are you sure you want to delete "${brand.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(brandListProvider.notifier).deleteBrand(brand.id);
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
