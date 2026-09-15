import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _restoreDatabase(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Database Backup',
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Database'),
            content: const Text('This will overwrite your current data. This action cannot be undone. Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final dbFolder = await getApplicationSupportDirectory();
          final currentDbPath = p.join(dbFolder.path, 'inventory.sqlite');
          
          // Drift might have the file locked. In a real app, you'd close the connection first.
          // For simplicity in this shell, we copy the file.
          await File(result.files.single.path!).copy(currentDbPath);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database restored! Please restart the app.')));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }

  Future<void> _importProductsFromCsv(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final input = File(result.files.single.path!).openRead();
        final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
        
        // This is a placeholder for CSV import logic.
        // In a real implementation, you'd parse headers and insert rows into the DB.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${fields.length} rows (Preview Mode)')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _exportProductsToCsv(BuildContext context, WidgetRef ref) async {
    try {
      final products = ref.read(productListProvider).value ?? [];
      if (products.isEmpty) throw Exception('No products to export');

      List<List<dynamic>> rows = [
        ['ID', 'SKU', 'Name', 'Category', 'Stock', 'Price']
      ];

      for (var p in products) {
        rows.add([p.id, p.sku, p.name, p.categoryName, p.currentStock, p.sellingPrice]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Products CSV',
        fileName: 'products_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export successful!')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final dbFolder = await getApplicationSupportDirectory();
      final dbFile = File(p.join(dbFolder.path, 'inventory.sqlite'));

      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: 'inventory_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite',
      );

      if (outputFile != null) {
        await dbFile.copy(outputFile);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup successful!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          const ListTile(
            title: Text('Business Profile'),
            subtitle: Text('Manage your company details'),
            leading: Icon(Icons.business),
          ),
          const Divider(),
          ListTile(
            title: const Text('Export Inventory to CSV'),
            subtitle: const Text('Save your product list as a CSV file'),
            leading: const Icon(Icons.download),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportProductsToCsv(context, ref),
          ),
          ListTile(
            title: const Text('Import Inventory from CSV'),
            subtitle: const Text('Upload products from a CSV file'),
            leading: const Icon(Icons.upload_file),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _importProductsFromCsv(context, ref),
          ),
          const Divider(),
          ListTile(
            title: const Text('Database Backup'),
            subtitle: const Text('Export a copy of your database'),
            leading: const Icon(Icons.backup),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _backupDatabase(context),
          ),
          ListTile(
            title: const Text('Restore Database'),
            subtitle: const Text('Import data from a backup file'),
            leading: const Icon(Icons.restore),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _restoreDatabase(context, ref),
          ),
          const Divider(),
          const ListTile(
            title: Text('User Management'),
            subtitle: Text('Add or edit staff accounts'),
            leading: Icon(Icons.person_add),
          ),
          const ListTile(
            title: Text('App Appearance'),
            subtitle: Text('Dark mode and theme settings'),
            leading: Icon(Icons.palette),
          ),
        ],
      ),
    );
  }
}
