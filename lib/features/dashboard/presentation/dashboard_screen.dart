import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:inventory_system_software/features/inventory/domain/models/stock_transaction.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final transactionsAsync = ref.watch(stockTransactionListProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            productsAsync.when(
              data: (List<Product> products) {
                final totalProducts = products.length;
                final lowStock = products.where((p) => p.currentStock <= p.minStock).length;
                final outOfStock = products.where((p) => p.currentStock <= 0).length;
                final totalStock = products.fold<int>(0, (sum, p) => sum + p.currentStock);

                return GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard('Total Products', totalProducts.toString(), Icons.inventory_2, Colors.blue),
                    _StatCard('Total Stock', totalStock.toString(), Icons.analytics, Colors.green),
                    _StatCard('Low Stock', lowStock.toString(), Icons.warning, Colors.orange),
                    _StatCard('Out of Stock', outOfStock.toString(), Icons.error, Colors.red),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: transactionsAsync.when(
                data: (List<StockTransaction> transactions) => Card(
                  child: ListView.builder(
                    itemCount: transactions.take(10).length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(tx.type).withValues(alpha: 0.1),
                          child: Icon(_getIcon(tx.type), color: _getColor(tx.type), size: 20),
                        ),
                        title: Text('${tx.productName} (${tx.type.value})'),
                        subtitle: Text('Quantity: ${tx.quantity} | By ${tx.userName}'),
                        trailing: Text(
                          '${tx.createdAt.hour}:${tx.createdAt.minute}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.stockIn: return Icons.arrow_downward;
      case StockTransactionType.stockOut: return Icons.arrow_upward;
      case StockTransactionType.adjustment: return Icons.tune;
      case StockTransactionType.damage: return Icons.broken_image;
      case StockTransactionType.sale: return Icons.shopping_cart;
      case StockTransactionType.purchase: return Icons.shopping_bag;
      default: return Icons.history;
    }
  }

  Color _getColor(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.stockIn:
      case StockTransactionType.purchase:
      case StockTransactionType.returnIn:
        return Colors.green;
      case StockTransactionType.stockOut:
      case StockTransactionType.sale:
      case StockTransactionType.damage:
      case StockTransactionType.returnOut:
        return Colors.red;
      case StockTransactionType.adjustment:
        return Colors.blue;
      }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
