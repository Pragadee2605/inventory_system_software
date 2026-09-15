import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/features/sales/presentation/providers/sales_provider.dart';
import 'package:inventory_system_software/features/customers/presentation/providers/customer_provider.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/sales/domain/repositories/sales_repository.dart';
import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart';
import 'package:inventory_system_software/features/customers/domain/models/customer.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart';
import 'package:inventory_system_software/core/services/barcode_scanner_service.dart';
import 'package:inventory_system_software/features/products/presentation/product_screen.dart';
import 'package:inventory_system_software/core/widgets/permission_gate.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreateSaleDialog(context, ref),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('New Sale'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: salesAsync.when(
        data: (List<SalesOrder> sales) => sales.isEmpty
            ? const Center(child: Text('No sales found.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: sales.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return ListTile(
                        title: Text(sale.invoiceNumber),
                        subtitle: Text('${sale.customerName ?? "Walk-in"} | ${DateFormat('dd MMM yyyy').format(sale.saleDate)}'),
                        trailing: Text('₹${sale.totalAmount.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    },
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showCreateSaleDialog(BuildContext context, WidgetRef ref) {
    int? selectedCustomerId;
    List<SalesItemDraft> cartItems = [];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final List<Customer> customers = ref.watch(customerListProvider).value ?? [];
          final List<Product> products = ref.watch(productListProvider).value ?? [];
          double total = cartItems.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));

          return AlertDialog(
            title: const Text('Create New Sale'),
            content: SizedBox(
              width: 700,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedCustomerId,
                      decoration: const InputDecoration(labelText: 'Customer (Optional)'),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('Walk-in Customer')),
                        ...customers.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => selectedCustomerId = v),
                    ),
                    const Divider(height: 32),
                    const Text('Cart Items', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, idx) {
                          final item = cartItems[idx];
                          final prod = products.firstWhere((p) => p.id == item.productId);
                          return ListTile(
                            title: Text(prod.name),
                            subtitle: Text('Qty: ${item.quantity} x ₹${item.unitPrice}'),
                            trailing: Text('₹${(item.quantity * item.unitPrice).toStringAsFixed(2)}'),
                            onLongPress: () => setState(() => cartItems.removeAt(idx)),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Items: ${cartItems.length}'),
                        Text('Total Amount: ₹${total.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _addItemToCart(context, ref, (item) => setState(() => cartItems.add(item))),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product to Cart'),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () async {
                            final scanned = await BarcodeScannerService.scanBarcode(context);
                            if (scanned == null) return;

                            final prod = await ref.read(productRepositoryProvider).getProductByBarcode(scanned);
                            if (prod == null) {
                              // Product not found
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Product Not Found'),
                                  content: Text('Barcode:\n$scanned\n\nThis barcode is not registered in the inventory.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    PermissionGate(
                                      permission: 'PRODUCT_MANAGE',
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.pop(context); // close sale dialog
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen()));
                                        },
                                        child: const Text('Create Product'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Add to cart with quantity rules and stock validation
                            final existingIndex = cartItems.indexWhere((c) => c.productId == prod.id);
                            if (existingIndex >= 0) {
                              final existing = cartItems[existingIndex];
                              final newQty = existing.quantity + 1;
                              if (newQty > prod.currentStock) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient stock. Available: ${prod.currentStock}')));
                                return;
                              }
                              setState(() => cartItems[existingIndex] = SalesItemDraft(productId: existing.productId, quantity: newQty, unitPrice: existing.unitPrice));
                            } else {
                              if (prod.currentStock <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient stock.')));
                                return;
                              }
                              setState(() => cartItems.add(SalesItemDraft(productId: prod.id, quantity: 1, unitPrice: prod.sellingPrice)));
                            }

                          },
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Scan Product'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: cartItems.isEmpty ? null : () {
                  ref.read(salesListProvider.notifier).createSale(
                    customerId: selectedCustomerId,
                    items: cartItems,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Complete Sale'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addItemToCart(BuildContext context, WidgetRef ref, Function(SalesItemDraft) onAdd) {
    int? selectedProdId;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final List<Product> products = ref.watch(productListProvider).value ?? [];
          return AlertDialog(
            title: const Text('Add to Cart'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedProdId,
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedProdId = v;
                      if (v != null) {
                        final p = products.firstWhere((prod) => prod.id == v);
                        priceController.text = p.sellingPrice.toString();
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Product'),
                ),
                TextFormField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity')),
                TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Unit Price')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedProdId != null) {
                    onAdd(SalesItemDraft(
                      productId: selectedProdId!,
                      quantity: int.parse(qtyController.text),
                      unitPrice: double.parse(priceController.text),
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add to Cart'),
              ),
            ],
          );
        },
      ),
    );
  }
}
