import 'local_data_source.dart';
import 'local_data_source_config.dart';
import '../engines/hive/hive_data_source.dart';
import '../engines/isar/isar_data_source.dart';

abstract final class LocalDataSourceFactory {
  static LocalDataSource? _instance;

  static LocalDataSource get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('LocalDataSourceFactory has not been initialized. Call create() first.');
    }
    return inst;
  }

  static Future<LocalDataSource> create(LocalDataSourceConfig config) async {
    final existing = _instance;
    if (existing != null) {
      await existing.dispose();
    }

    final LocalDataSource dataSource = switch (config) {
      HiveDataSourceConfig() => HiveDataSource(config: config),
      IsarDataSourceConfig() => IsarDataSource(config: config),
    };

    await dataSource.init();
    _instance = dataSource;
    return dataSource;
  }

  static Future<void> reset() async {
    await _instance?.dispose();
    _instance = null;
  }
}
