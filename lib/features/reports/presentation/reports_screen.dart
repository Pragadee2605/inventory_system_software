import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_system_software/features/sales/presentation/providers/sales_provider.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesListProvider);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 2, child: _buildRevenueProfitSummary(ref)),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildSalesChart(salesAsync)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStockDistribution(productsAsync)),
                const SizedBox(width: 24),
                Expanded(child: _buildLowStockReport(productsAsync)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueProfitSummary(WidgetRef ref) {
    final profitAsync = ref.watch(salesTotalProfitProvider);
    final salesAsync = ref.watch(salesListProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _summaryItem('Total Revenue', salesAsync.value?.fold(0.0, (sum, s) => sum! + s.totalAmount) ?? 0.0, Colors.indigo),
            const Divider(height: 32),
            _summaryItem('Gross Profit', profitAsync.value ?? 0.0, Colors.green),
            const Divider(height: 32),
            _summaryItem('Net Margin (%)', _calculateMargin(salesAsync.value, profitAsync.value), Colors.orange),
          ],
        ),
      ),
    );
  }

  double _calculateMargin(List<dynamic>? sales, double? profit) {
    if (sales == null || sales.isEmpty || profit == null || profit == 0) return 0.0;
    final totalRevenue = sales.fold(0.0, (sum, s) => sum! + s.totalAmount);
    return (profit / totalRevenue) * 100;
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          label.contains('%') ? '${value.toStringAsFixed(1)}%' : '₹${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _buildSalesChart(AsyncValue<List<dynamic>> salesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Sales Transaction Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: salesAsync.when(
                data: (sales) {
                  if (sales.isEmpty) return const Center(child: Text('No sales data recorded'));
                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sales.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.totalAmount)).toList(),
                          isCurved: true,
                          color: Colors.indigo,
                          barWidth: 4,
                          belowBarData: BarAreaData(show: true, color: Colors.indigo.withValues(alpha: 0.1)),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockDistribution(AsyncValue<List<dynamic>> productsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Inventory Composition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) return const Center(child: Text('No products in catalog'));
                  return PieChart(
                    PieChartData(
                      sections: products.take(5).map((p) => PieChartSectionData(
                        value: p.currentStock.toDouble(),
                        title: p.name,
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        color: Colors.primaries[products.indexOf(p) % Colors.primaries.length],
                      )).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockReport(AsyncValue<List<dynamic>> productsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Low Stock Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            productsAsync.when(
              data: (products) {
                final lowStock = products.where((p) => p.currentStock <= p.minStock).toList();
                if (lowStock.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('All products optimal.')));
                return SizedBox(
                  height: 250,
                  child: ListView.builder(
                    itemCount: lowStock.length,
                    itemBuilder: (context, idx) {
                      final p = lowStock[idx];
                      return ListTile(
                        dense: true,
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text('${p.currentStock} in stock', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
