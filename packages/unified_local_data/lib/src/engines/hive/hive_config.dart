import '../../core/unified_data_source_config.dart';

final class HiveEncryptionConfig {
  final List<int> key;
  const HiveEncryptionConfig({required this.key});
}

final class HiveDataSourceConfig extends UnifiedDataSourceConfig {
  final List<String> preloadBoxes;

  /// Collections that `drop()` always covers, on top of the ones the data
  /// source has recorded itself. For collections written by 1.1.x or
  /// earlier, which were never recorded. Unlike [preloadBoxes], these aren't
  /// opened at `init()`.
  final List<String> collections;

  final HiveEncryptionConfig? encryption;

  const HiveDataSourceConfig({
    required super.directory,
    this.preloadBoxes = const [],
    this.collections = const [],
    this.encryption,
  }) : super(engine: DatabaseEngine.hive);
}
