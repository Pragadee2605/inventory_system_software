import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:inventory_system_software/features/inventory/domain/models/stock_transaction.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart';

import '../../sales/presentation/providers/sales_provider.dart';

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
            _buildHeader(context, isDark),
            const SizedBox(height: 28),
            
            // KPI Metrics Grid
            productsAsync.when(
              data: (products) => _buildKpiGrid(context, products),
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            
            const SizedBox(height: 32),

            // Analytics & Insights - Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return SizedBox(
                    height: 400,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 7,
                          child: transactionsAsync.when(
                            data: (transactions) => _buildSalesTrendCard(context, transactions, isDark),
                            loading: () => const Card(child: Center(child: CircularProgressIndicator())),
                            error: (err, _) => Text('Error: $err'),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: productsAsync.when(
                            data: (products) => _buildAlertsPanel(context, products, isDark),
                            loading: () => const Card(child: Center(child: CircularProgressIndicator())),
                            error: (err, _) => Text('Error: $err'),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(
                        height: 350,
                        width: double.infinity,
                        child: transactionsAsync.when(
                          data: (transactions) => _buildSalesTrendCard(context, transactions, isDark),
                          loading: () => const Card(child: Center(child: CircularProgressIndicator())),
                          error: (err, _) => Text('Error: $err'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: productsAsync.when(
                          data: (products) => _buildAlertsPanel(context, products, isDark),
                          loading: () => const Card(child: Center(child: CircularProgressIndicator())),
                          error: (err, _) => Text('Error: $err'),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 32),

            // Recent Activity Section
            _buildActivityHeader(context, theme),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (transactions) => _buildActivityFeed(context, transactions, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
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
                  'Real-time inventory metrics, visual insights, and proactive stock management.',
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
            label: const Text('View Reports'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, List<Product> products) {
    return Consumer(
      builder: (context, ref, child) {
        final totalProducts = products.length;
        final lowStock = products.where((p) => p.currentStock <= p.minStock && p.currentStock > 0).length;
        final outOfStock = products.where((p) => p.currentStock <= 0).length;
        final profitAsync = ref.watch(salesTotalProfitProvider);

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: constraints.maxWidth > 1200 ? 1.8 : 1.5,
              children: [
                _StatCard(
                  title: 'Gross Profit',
                  value: '₹${profitAsync.value?.toStringAsFixed(0) ?? "0"}',
                  subtitle: 'Total net earnings',
                  badgeText: 'Net Revenue',
                  badgeColor: const Color(0xFF10B981),
                  icon: Icons.trending_up_rounded,
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF10B981),
                  onTap: () => context.go('/reports'),
                ),
                _StatCard(
                  title: 'Active SKUs',
                  value: totalProducts.toString(),
                  subtitle: 'Total unique products',
                  badgeText: 'Catalog Size',
                  badgeColor: const Color(0xFF4F46E5),
                  icon: Icons.inventory_2_rounded,
                  iconBgColor: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F46E5),
                  onTap: () => context.go('/products'),
                ),
                _StatCard(
                  title: 'Low Stock Alert',
                  value: lowStock.toString(),
                  subtitle: 'Items near threshold',
                  badgeText: lowStock > 0 ? 'Action Needed' : 'Optimal',
                  badgeColor: lowStock > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  icon: Icons.warning_amber_rounded,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  onTap: () => context.go('/inventory'),
                ),
                _StatCard(
                  title: 'Out of Stock',
                  value: outOfStock.toString(),
                  subtitle: 'Zero inventory items',
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
    );
  }

  Widget _buildSalesTrendCard(BuildContext context, List<StockTransaction> transactions, bool isDark) {
    // Group transactions by date for the last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    
    final salesData = last7Days.map((date) {
      final dailyTotal = transactions
          .where((tx) => tx.type == StockTransactionType.sale && 
                  tx.createdAt.year == date.year && 
                  tx.createdAt.month == date.month && 
                  tx.createdAt.day == date.day)
          .fold<double>(0, (sum, tx) => sum + tx.quantity.toDouble());
      return FlSpot(last7Days.indexOf(date).toDouble(), dailyTotal);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Stock units sold per day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Last 7 Days', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val % 1 != 0) return const SizedBox();
                          final index = val.toInt();
                          if (index < 0 || index >= last7Days.length) return const SizedBox();
                          final date = last7Days[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: salesData,
                      isCurved: true,
                      color: const Color(0xFF4F46E5),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [const Color(0xFF4F46E5).withValues(alpha: 0.3), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsPanel(BuildContext context, List<Product> products, bool isDark) {
    final criticalProducts = products.where((p) => p.currentStock <= p.minStock).toList()
      ..sort((a, b) => a.currentStock.compareTo(b.currentStock));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 8),
                Text('Procurement View', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (criticalProducts.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 40),
                      SizedBox(height: 12),
                      Text('All stock levels optimal', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: criticalProducts.take(5).length,
                  separatorBuilder: (context, _) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final p = criticalProducts[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${p.currentStock} left', 
                              style: TextStyle(
                                color: p.currentStock <= 0 ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: p.currentStock / (p.minStock * 2).clamp(1, 999999),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(p.currentStock <= 0 ? Colors.red : Colors.orange),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/inventory'),
                child: const Text('Reorder Items'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operations Stream',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Real-time record of all system activity',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => context.go('/audit'),
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('View Audit Log'),
        ),
      ],
    );
  }

  Widget _buildActivityFeed(BuildContext context, List<StockTransaction> transactions, ThemeData theme) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 48, color: theme.dividerColor),
                const SizedBox(height: 12),
                const Text('No recent activity recorded yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    final recentList = transactions.take(6).toList();
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
                Text(tx.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(tx.type.value.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            subtitle: Text('Qty: ${tx.quantity} | By ${tx.userName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: Text(_formatTime(tx.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          );
        },
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
        return const Color(0xFF10B981);
      case StockTransactionType.stockOut:
      case StockTransactionType.sale:
      case StockTransactionType.damage:
      case StockTransactionType.returnOut:
        return const Color(0xFFEF4444);
      case StockTransactionType.adjustment:
        return const Color(0xFF3B82F6);
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
