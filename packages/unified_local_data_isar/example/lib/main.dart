import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unified_local_data_isar/unified_local_data_isar.dart';

/// Stores and reads a few values through the Isar engine.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await UnifiedDataSourceFactory.create(
    IsarDataSourceConfig(directory: dir.path),
  );

  // Both writes commit together, or neither does.
  await db.transaction(() async {
    await db.put<String>('settings', 'theme', 'dark');
    await db.put<int>('settings', 'launches', 1);
  });

  final theme = await db.get<String>('settings', 'theme');
  debugPrint('Stored theme: $theme'); // Stored theme: dark
}
