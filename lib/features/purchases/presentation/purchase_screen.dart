import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/features/purchases/presentation/providers/purchase_provider.dart';
import 'package:inventory_system_software/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:inventory_system_software/features/purchases/domain/models/purchase_order.dart';
import 'package:inventory_system_software/features/suppliers/domain/models/supplier.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart';

class PurchaseScreen extends ConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchaseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showCreatePurchaseDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New Purchase'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: purchasesAsync.when(
        data: (List<PurchaseOrder> purchases) => purchases.isEmpty
            ? const Center(child: Text('No purchase orders found.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: purchases.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final po = purchases[index];
                      return ListTile(
                        title: Text(po.orderNumber),
                        subtitle: Text('${po.supplierName} | ${DateFormat('dd MMM yyyy').format(po.orderDate)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${po.totalAmount.toStringAsFixed(2)}', 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            _getStatusChip(po.status),
                          ],
                        ),
                        onTap: () => _showReceiveDialog(context, ref, po.id),
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

  Widget _getStatusChip(String status) {
    Color color = Colors.grey;
    if (status == 'RECEIVED') color = Colors.green;
    if (status == 'PENDING') color = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  void _showCreatePurchaseDialog(BuildContext context, WidgetRef ref) {
    int? selectedSupplierId;
    List<PurchaseItemDraft> draftItems = [];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final List<Supplier> suppliers = ref.watch(supplierListProvider).value ?? [];
          final List<Product> products = ref.watch(productListProvider).value ?? [];

          return AlertDialog(
            title: const Text('New Purchase Order'),
            content: SizedBox(
              width: 600,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedSupplierId,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (v) => setState(() => selectedSupplierId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const Divider(height: 32),
                    const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...draftItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final prod = products.firstWhere((p) => p.id == item.productId);
                      return ListTile(
                        title: Text(prod.name),
                        subtitle: Text('Qty: ${item.quantity} | Price: ₹${item.unitPrice}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => draftItems.removeAt(idx)),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () => _addItemToDraft(context, ref, (item) => setState(() => draftItems.add(item))),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: draftItems.isEmpty || selectedSupplierId == null ? null : () {
                  ref.read(purchaseListProvider.notifier).createPurchase(
                    supplierId: selectedSupplierId!,
                    items: draftItems,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Create Order'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addItemToDraft(BuildContext context, WidgetRef ref, Function(PurchaseItemDraft) onAdd) {
    int? selectedProdId;
    final qtyController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final List<Product> products = ref.watch(productListProvider).value ?? [];
          return AlertDialog(
            title: const Text('Add Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedProdId,
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) => setState(() => selectedProdId = v),
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
                    onAdd(PurchaseItemDraft(
                      productId: selectedProdId!,
                      quantity: int.parse(qtyController.text),
                      unitPrice: double.parse(priceController.text),
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReceiveDialog(BuildContext context, WidgetRef ref, int orderId) async {
    final order = await ref.read(purchaseRepositoryProvider).getPurchaseById(orderId);
    if (order == null || order.status == 'RECEIVED') return;

    Map<int, int> receiveMap = {};
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Receive Items: ${order.orderNumber}'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: order.items.map((item) {
                  final remaining = item.quantity - item.receivedQuantity;
                  if (remaining <= 0) return const SizedBox.shrink();
                  return ListTile(
                    title: Text(item.productName),
                    subtitle: Text('Pending: $remaining'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: '0',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => receiveMap[item.id] = int.tryParse(v) ?? 0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  ref.read(purchaseListProvider.notifier).receiveItems(orderId, receiveMap);
                  Navigator.pop(context);
                },
                child: const Text('Confirm Receipt'),
              ),
            ],
          );
        },
      ),
    );
  }
}
