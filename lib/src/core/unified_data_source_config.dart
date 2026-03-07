import '../engines/hive/hive_config.dart';
import '../engines/isar/isar_config.dart';

enum DatabaseEngine { hive, isar }

abstract class UnifiedDataSourceConfig {
  final String directory;
  final DatabaseEngine engine;

  const UnifiedDataSourceConfig({
    required this.directory,
    required this.engine,
  });

  factory UnifiedDataSourceConfig.hive({
    required String directory,
    List<String> preloadBoxes,
    HiveEncryptionConfig? encryption,
  }) = HiveDataSourceConfig;

  factory UnifiedDataSourceConfig.isar({
    required String directory,
    required List<dynamic> schemas,
    int maxSizeMiB,
    bool inspector,
  }) = IsarDataSourceConfig;
}
