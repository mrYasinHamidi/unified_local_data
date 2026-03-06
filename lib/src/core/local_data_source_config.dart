import '../engines/hive/hive_config.dart';
import '../engines/isar/isar_config.dart';

enum DatabaseEngine { hive, isar }

sealed class LocalDataSourceConfig {
  final String directory;
  final DatabaseEngine engine;

  const LocalDataSourceConfig({
    required this.directory,
    required this.engine,
  });

  factory LocalDataSourceConfig.hive({
    required String directory,
    List<String> preloadBoxes = const [],
    HiveEncryptionConfig? encryption,
  }) = HiveDataSourceConfig;

  factory LocalDataSourceConfig.isar({
    required String directory,
    required List<dynamic> schemas,
    int maxSizeMiB = 256,
    bool inspector = false,
  }) = IsarDataSourceConfig;
}
