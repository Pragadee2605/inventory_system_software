import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart';
import 'package:inventory_system_software/features/categories/presentation/providers/category_provider.dart';
import 'package:inventory_system_software/features/brands/presentation/providers/brand_provider.dart';
import 'package:inventory_system_software/core/widgets/permission_gate.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ProductScreen');

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          PermissionGate(
            permission: 'PRODUCT_MANAGE',
            child: ElevatedButton.icon(
              onPressed: () => _showProductDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: productsAsync.when(
        data: (List<Product> products) => products.isEmpty
            ? const Center(child: Text('No products found.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('SKU')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Brand')),
                          DataColumn(label: Text('Stock')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: products.map((product) {
                          return DataRow(cells: [
                            DataCell(Text(product.sku)),
                            DataCell(Text(product.name)),
                            DataCell(Text(product.categoryName)),
                            DataCell(Text(product.brandName ?? '-')),
                            DataCell(Text(
                              product.currentStock.toString(),
                              style: TextStyle(
                                color: product.currentStock <= product.minStock ? Colors.red : null,
                                fontWeight: product.currentStock <= product.minStock ? FontWeight.bold : null,
                              ),
                            )),
                            DataCell(Text('₹${product.sellingPrice}')),
                            DataCell(PermissionGate(
                              permission: 'PRODUCT_MANAGE',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showProductDialog(context, ref, product: product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, ref, product),
                                  ),
                                ],
                              ),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showProductDialog(BuildContext context, WidgetRef ref, {Product? product}) {
    final formKey = GlobalKey<FormState>();
    final skuController = TextEditingController(text: product?.sku);
    final barcodeController = TextEditingController(text: product?.barcode);
    final nameController = TextEditingController(text: product?.name);
    final purchasePriceController = TextEditingController(text: product?.purchasePrice.toString() ?? '0.0');
    final sellingPriceController = TextEditingController(text: product?.sellingPrice.toString() ?? '0.0');
    final minStockController = TextEditingController(text: product?.minStock.toString() ?? '5');
    
    int? selectedCategoryId = product?.categoryId;
    int? selectedBrandId = product?.brandId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
          final categories = ref.watch(categoryListProvider).value ?? [];
          final brands = ref.watch(brandListProvider).value ?? [];

          final canSave = categories.isNotEmpty;
          _logger.info('Loaded categories=${categories.length}, brands=${brands.length} for product form');

          return AlertDialog(
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (categories.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('No categories found. Add a category before creating products.'),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: skuController,
                              decoration: const InputDecoration(labelText: 'SKU *'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: barcodeController,
                              decoration: const InputDecoration(labelText: 'Barcode'),
                            ),
                          ),
                        ],
                        ),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Product Name *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: categories.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : null,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: categories.isEmpty
                            ? const []
                            : categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: canSave ? (v) => setState(() => selectedCategoryId = v) : null,
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: brands.any((b) => b.id == selectedBrandId) ? selectedBrandId : null,
                        decoration: const InputDecoration(labelText: 'Brand'),
                        items: brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                        onChanged: (v) => setState(() => selectedBrandId = v),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: purchasePriceController,
                              decoration: const InputDecoration(labelText: 'Purchase Price'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: sellingPriceController,
                              decoration: const InputDecoration(labelText: 'Selling Price'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: minStockController,
                        decoration: const InputDecoration(labelText: 'Minimum Stock Level'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: canSave
                    ? () {
                        if (formKey.currentState!.validate()) {
                          _logger.info('Saving product: sku=${skuController.text}, categoryId=$selectedCategoryId');
                          if (product == null) {
                            ref.read(productListProvider.notifier).addProduct(
                                  sku: skuController.text,
                                  barcode: barcodeController.text,
                                  name: nameController.text,
                                  categoryId: selectedCategoryId!,
                                  brandId: selectedBrandId,
                                  purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
                                  sellingPrice: double.tryParse(sellingPriceController.text) ?? 0.0,
                                  minStock: int.tryParse(minStockController.text) ?? 5,
                                );
                          } else {
                            ref.read(productListProvider.notifier).updateProduct(
                                  id: product.id,
                                  sku: skuController.text,
                                  barcode: barcodeController.text,
                                  name: nameController.text,
                                  categoryId: selectedCategoryId!,
                                  brandId: selectedBrandId,
                                  purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
                                  sellingPrice: double.tryParse(sellingPriceController.text) ?? 0.0,
                                  minStock: int.tryParse(minStockController.text) ?? 5,
                                );
                          }
                          Navigator.pop(context);
                        }
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(productListProvider.notifier).deleteProduct(product.id);
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
