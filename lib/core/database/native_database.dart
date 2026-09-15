import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

DatabaseConnection openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final dbFolder = await getApplicationSupportDirectory();
    await dbFolder.create(recursive: true);
    final file = File(p.join(dbFolder.path, 'inventory.sqlite'));
    final executor = NativeDatabase.createInBackground(file);
    return DatabaseConnection(executor);
  }));
}
