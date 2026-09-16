import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/app.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/core/services/logging_service.dart';

import 'features/customers/presentation/providers/customer_provider.dart';
import 'features/products/presentation/providers/product_provider.dart';
import 'features/sales/presentation/providers/sales_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggingService.init();

  final database = AppDatabase();
  await database.ensureDefaultAdmin();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
    ],
  );

  // Non-blocking warm up: start loading but don't wait indefinitely if it takes too long
  _warmUpProviders(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const InventoryApp(),
    ),
  );
}

void _warmUpProviders(ProviderContainer container) async {
  try {
    // Start these futures but let the app continue to boot
    Future.wait([
      container.read(productListProvider.future),
      container.read(customerListProvider.future),
      container.read(salesListProvider.future),
    ]).timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('Warm up timed out after 5 seconds - continuing in background');
      return [];
    });
  } catch (e) {
    debugPrint('Error warming up providers: $e');
  }
}
