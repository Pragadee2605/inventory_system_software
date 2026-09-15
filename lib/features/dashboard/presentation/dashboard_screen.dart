import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFF4F46E5), const Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Executive Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Real-time inventory metrics, stock alerts, and enterprise operations stream.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/reports'),
                    icon: const Icon(Icons.analytics_rounded, size: 18),
                    label: const Text('View Analytics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4F46E5),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // KPI Metrics Grid
            productsAsync.when(
              data: (List<Product> products) {
                final totalProducts = products.length;
                final lowStock = products.where((p) => p.currentStock <= p.minStock && p.currentStock > 0).length;
                final outOfStock = products.where((p) => p.currentStock <= 0).length;
                final totalStock = products.fold<int>(0, (sum, p) => sum + p.currentStock);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1000
                        ? 4
                        : constraints.maxWidth > 650
                            ? 2
                            : 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth > 1200 ? 1.8 : 1.5,
                      children: [
                        _StatCard(
                          title: 'Total Products',
                          value: totalProducts.toString(),
                          subtitle: 'Active SKUs cataloged',
                          badgeText: 'Active Catalog',
                          badgeColor: const Color(0xFF4F46E5),
                          icon: Icons.inventory_2_rounded,
                          iconBgColor: const Color(0xFFEEF2FF),
                          iconColor: const Color(0xFF4F46E5),
                          onTap: () => context.go('/products'),
                        ),
                        _StatCard(
                          title: 'Total Stock Volume',
                          value: totalStock.toString(),
                          subtitle: 'Units in warehouses',
                          badgeText: 'Optimal Level',
                          badgeColor: const Color(0xFF10B981),
                          icon: Icons.warehouse_rounded,
                          iconBgColor: const Color(0xFFD1FAE5),
                          iconColor: const Color(0xFF10B981),
                          onTap: () => context.go('/inventory'),
                        ),
                        _StatCard(
                          title: 'Low Stock Alert',
                          value: lowStock.toString(),
                          subtitle: 'Items near threshold',
                          badgeText: lowStock > 0 ? 'Requires Action' : 'Optimal',
                          badgeColor: lowStock > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          icon: Icons.warning_amber_rounded,
                          iconBgColor: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          onTap: () => context.go('/inventory'),
                        ),
                        _StatCard(
                          title: 'Out of Stock',
                          value: outOfStock.toString(),
                          subtitle: 'Items with zero inventory',
                          badgeText: outOfStock > 0 ? 'Critical' : 'Healthy',
                          badgeColor: outOfStock > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          icon: Icons.error_outline_rounded,
                          iconBgColor: const Color(0xFFFEE2E2),
                          iconColor: const Color(0xFFEF4444),
                          onTap: () => context.go('/inventory'),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Failed to load metrics: $err', style: const TextStyle(color: Color(0xFFEF4444))),
              ),
            ),
            const SizedBox(height: 32),
            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Audit & Transactions Feed',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Real-time record of stock transfers, movements, and adjustments',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/audit'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View All Logs'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (List<StockTransaction> transactions) {
                if (transactions.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: theme.dividerColor),
                            const SizedBox(height: 12),
                            const Text(
                              'No recent transaction activity recorded yet.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final recentList = transactions.take(8).toList();

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = recentList[index];
                      final color = _getColor(tx.type);
                      final icon = _getIcon(tx.type);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(
                              tx.productName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tx.type.value.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Quantity: ${tx.quantity} units | Executed by ${tx.userName}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        trailing: Text(
                          _formatTime(tx.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error loading activity: $err'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  IconData _getIcon(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.stockIn: return Icons.south_west_rounded;
      case StockTransactionType.stockOut: return Icons.north_east_rounded;
      case StockTransactionType.adjustment: return Icons.tune_rounded;
      case StockTransactionType.damage: return Icons.report_problem_rounded;
      case StockTransactionType.sale: return Icons.point_of_sale_rounded;
      case StockTransactionType.purchase: return Icons.shopping_bag_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  Color _getColor(StockTransactionType type) {
    switch (type) {
      case StockTransactionType.stockIn:
      case StockTransactionType.purchase:
      case StockTransactionType.returnIn:
        return const Color(0xFF10B981); // Emerald
      case StockTransactionType.stockOut:
      case StockTransactionType.sale:
      case StockTransactionType.damage:
      case StockTransactionType.returnOut:
        return const Color(0xFFEF4444); // Rose
      case StockTransactionType.adjustment:
        return const Color(0xFF3B82F6); // Blue
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? iconColor.withValues(alpha: 0.15) : iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
