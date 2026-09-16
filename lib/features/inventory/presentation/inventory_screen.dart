import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/features/inventory/domain/models/stock_transaction.dart';
import 'package:inventory_system_software/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(stockTransactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Movements'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showTransactionDialog(context, ref, StockTransactionType.stockIn),
            icon: const Icon(Icons.add),
            label: const Text('Stock In'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showTransactionDialog(context, ref, StockTransactionType.stockOut),
            icon: const Icon(Icons.remove),
            label: const Text('Stock Out'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showTransactionDialog(context, ref, StockTransactionType.adjustment),
            icon: const Icon(Icons.tune),
            label: const Text('Adjustment'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: transactionsAsync.when(
        data: (List<StockTransaction> transactions) => transactions.isEmpty
            ? const Center(child: Text('No transactions recorded.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return ListTile(
                        leading: _getIcon(tx.type),
                        title: Text('${tx.productName} (${tx.sku})'),
                        subtitle: Text(
                          '${tx.type.value} | Qty: ${tx.quantity} | Balance: ${tx.newStock} | By: ${tx.userName}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(tx.createdAt)),
                            Text(DateFormat('HH:mm').format(tx.createdAt),
                                style: Theme.of(context).textTheme.bodySmall),
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

  Widget _getIcon(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.stockIn:
        return const Icon(Icons.arrow_downward, color: Colors.green);
      case StockTransactionType.stockOut:
        return const Icon(Icons.arrow_upward, color: Colors.red);
      case StockTransactionType.adjustment:
        return const Icon(Icons.tune, color: Colors.blue);
      case StockTransactionType.damage:
        return const Icon(Icons.broken_image, color: Colors.orange);
      default:
        return const Icon(Icons.history);
    }
  }

  void _showTransactionDialog(BuildContext context, WidgetRef ref, StockTransactionType type) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    int? selectedProductId;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final productsAsync = ref.watch(productListProvider);

          return productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load products: $err'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
            ),
            data: (products) => StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(type == StockTransactionType.stockIn
                      ? 'Add Stock (In)'
                      : type == StockTransactionType.stockOut
                          ? 'Remove Stock (Out)'
                          : 'Stock Adjustment'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: selectedProductId,
                          decoration: const InputDecoration(labelText: 'Select Product *'),
                          items: products
                              .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.sku})')))
                              .toList(),
                          onChanged: (v) => setState(() => selectedProductId = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: type == StockTransactionType.adjustment ? 'Quantity (+/-)' : 'Quantity',
                            helperText: type == StockTransactionType.adjustment ? 'Use negative for deduction' : null,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (int.tryParse(v) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: reasonController,
                          decoration: const InputDecoration(labelText: 'Reason / Reference'),
                          maxLines: 2,
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
                          ref.read(stockTransactionListProvider.notifier).addTransaction(
                                productId: selectedProductId!,
                                type: type,
                                quantity: int.parse(quantityController.text),
                                reason: reasonController.text,
                              );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
