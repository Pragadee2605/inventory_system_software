import 'dart:developer';
import 'package:logging/logging.dart';

class LoggingService {
  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      log('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        log('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        log('StackTrace: ${record.stackTrace}');
      }
    });
  }
}
