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
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSalesChart(salesAsync)),
                const SizedBox(width: 24),
                Expanded(child: _buildStockDistribution(productsAsync)),
              ],
            ),
            const SizedBox(height: 24),
            _buildLowStockReport(productsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(AsyncValue<List<dynamic>> salesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Sales Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: salesAsync.when(
                data: (sales) {
                  if (sales.isEmpty) return const Center(child: Text('No sales data'));
                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sales.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.totalAmount)).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 4,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
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
            const Text('Stock Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) return const Center(child: Text('No products'));
                  return PieChart(
                    PieChartData(
                      sections: products.take(5).map((p) => PieChartSectionData(
                        value: p.currentStock.toDouble(),
                        title: p.name,
                        radius: 50,
                        color: Colors.primaries[products.indexOf(p) % Colors.primaries.length],
                      )).toList(),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
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
            const Text('Low Stock Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            productsAsync.when(
              data: (products) {
                final lowStock = products.where((p) => p.currentStock <= p.minStock).toList();
                if (lowStock.isEmpty) return const Text('All products are well-stocked.');
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: lowStock.length,
                  itemBuilder: (context, idx) {
                    final p = lowStock[idx];
                    return ListTile(
                      title: Text(p.name),
                      trailing: Text('${p.currentStock} / ${p.minStock}', style: const TextStyle(color: Colors.red)),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
