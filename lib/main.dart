import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/app.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/core/services/logging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Logging
  LoggingService.init();

  // Initialize Database (Drift)
  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const InventoryApp(),
    ),
  );
}
