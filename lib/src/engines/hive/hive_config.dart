import '../../core/local_data_source_config.dart';

final class HiveEncryptionConfig {
  final List<int> key;
  const HiveEncryptionConfig({required this.key});
}

final class HiveDataSourceConfig extends LocalDataSourceConfig {
  final List<String> preloadBoxes;
  final HiveEncryptionConfig? encryption;

  const HiveDataSourceConfig({
    required super.directory,
    this.preloadBoxes = const [],
    this.encryption,
  }) : super(engine: DatabaseEngine.hive);
}
