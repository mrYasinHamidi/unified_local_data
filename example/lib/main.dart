import 'package:flutter/material.dart';
import 'package:unified_local_data/local_data_source.dart';
import 'package:path_provider/path_provider.dart';

/// A simple example demonstrating how to use [unified_local_data] with the
/// Hive CE engine.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the data source with the Hive engine.
  final dir = await getApplicationDocumentsDirectory();

  final dataSource = await LocalDataSourceFactory.create(
    LocalDataSourceConfig.hive(
      directory: dir.path,
      preloadBoxes: ['settings', 'cache'],
    ),
  );

  // Put a simple string value.
  await dataSource.put<String>('settings', 'theme', 'dark');

  // Read it back.
  final String? theme = await dataSource.get<String>('settings', 'theme');
  debugPrint('Stored theme: $theme'); // Stored theme: dark
}
