import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/app.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/core/services/logging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggingService.init();

  final database = AppDatabase();
  await database.ensureDefaultAdmin();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const InventoryApp(),
    ),
  );
}
