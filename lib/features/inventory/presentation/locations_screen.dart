import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/core/database/database.dart';

final locationsProvider = FutureProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.locations).get();
});

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Locations'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddLocationDialog(context, ref),
            icon: const Icon(Icons.add_location),
            label: const Text('Add Location'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: locationsAsync.when(
        data: (locations) => locations.isEmpty
            ? const Center(child: Text('No locations defined. Add a warehouse or store.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.location_on)),
                        title: Text(loc.name),
                        subtitle: Text('Code: ${loc.code}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final db = ref.read(databaseProvider);
                            await (db.delete(db.locations)..where((t) => t.id.equals(loc.id))).go();
                            ref.invalidate(locationsProvider);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Location'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Location Name (e.g. Main Warehouse)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Location Code (e.g. WH-01)'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final db = ref.read(databaseProvider);
                await db.into(db.locations).insert(
                  LocationsCompanion.insert(name: nameController.text, code: codeController.text),
                );
                ref.invalidate(locationsProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
