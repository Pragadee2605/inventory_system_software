import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/categories/presentation/providers/category_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _restoreDatabase(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Database Backup (.sqlite)',
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        if (!await backupFile.exists() || await backupFile.length() == 0) {
          throw Exception('Selected file is invalid or empty.');
        }

        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Database Restore'),
            content: const Text(
              'This operation will replace your active database with the selected backup file. '
              'All unsaved changes will be overwritten. Proceed?',
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore Database'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final dbFolder = await getApplicationSupportDirectory();
          final currentDbPath = p.join(dbFolder.path, 'inventory.sqlite');
          
          await backupFile.copy(currentDbPath);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Database restored successfully! Please restart the application.'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database restore failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
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

        if (fields.length <= 1) {
          throw Exception('CSV file is empty or missing data rows.');
        }

        final categories = await ref.read(categoryListProvider.future);
        final defaultCatId = categories.isNotEmpty ? categories.first.id : 1;
        int importedCount = 0;

        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.length < 3) continue;

          final sku = row[0].toString().trim();
          final name = row[1].toString().trim();
          final price = double.tryParse(row[2].toString()) ?? 0.0;
          final stock = row.length > 3 ? int.tryParse(row[3].toString()) ?? 0 : 0;

          if (sku.isNotEmpty && name.isNotEmpty) {
            try {
              await ref.read(productRepositoryProvider).createProduct(
                sku: sku,
                name: name,
                categoryId: defaultCatId,
                sellingPrice: price,
                currentStock: stock,
              );
              importedCount++;
            } catch (_) {
              // Ignore duplicates or invalid rows gracefully
            }
          }
        }

        ref.invalidate(productListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $importedCount product(s) from CSV.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _exportProductsToCsv(BuildContext context, WidgetRef ref) async {
    try {
      final products = ref.read(productListProvider).value ?? [];
      if (products.isEmpty) throw Exception('No products available to export');

      List<List<dynamic>> rows = [
        ['SKU', 'Name', 'Category', 'Selling Price', 'Current Stock', 'Min Stock']
      ];

      for (var p in products) {
        rows.add([p.sku, p.name, p.categoryName, p.sellingPrice, p.currentStock, p.minStock]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Products CSV',
        fileName: 'nexus_products_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product catalog exported successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final dbFolder = await getApplicationSupportDirectory();
      final dbFile = File(p.join(dbFolder.path, 'inventory.sqlite'));

      if (!await dbFile.exists()) {
        throw Exception('Database file not found at expected path.');
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup (.sqlite)',
        fileName: 'nexus_inventory_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite',
      );

      if (outputFile != null) {
        await dbFile.copy(outputFile);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database backup created successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings & Administration',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure database backups, data exports, user accounts, and platform options.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 28),
            // User Management Card
            _buildSectionCard(
              context,
              title: 'USER & SECURITY MANAGEMENT',
              children: [
                ListTile(
                  title: const Text('Manage User Accounts', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Add staff, assign roles (Admin, Manager, Staff), and disable accounts.'),
                  leading: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF4F46E5)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/users'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Data Import / Export Card
            _buildSectionCard(
              context,
              title: 'DATA IMPORT & EXPORT',
              children: [
                ListTile(
                  title: const Text('Export Inventory to CSV', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Export product catalog, current stock, and prices to CSV format.'),
                  leading: const Icon(Icons.download_rounded, color: Color(0xFF0284C7)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _exportProductsToCsv(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Import Products from CSV', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Bulk import products from structured CSV files.'),
                  leading: const Icon(Icons.upload_file_rounded, color: Color(0xFFD97706)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _importProductsFromCsv(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Backup & Restore Card
            _buildSectionCard(
              context,
              title: 'DATABASE BACKUP & DISASTER RECOVERY',
              children: [
                ListTile(
                  title: const Text('Create Full Database Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Save a standalone snapshot of your SQLite database to disk.'),
                  leading: const Icon(Icons.backup_rounded, color: Color(0xFF10B981)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _backupDatabase(context),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Restore Database from Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Restore database state from a saved .sqlite backup file.'),
                  leading: const Icon(Icons.restore_rounded, color: Color(0xFFEF4444)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _restoreDatabase(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
