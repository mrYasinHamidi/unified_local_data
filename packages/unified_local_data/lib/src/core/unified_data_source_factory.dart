import 'unified_data_source.dart';
import 'unified_data_source_config.dart';

/// Creates the app's [UnifiedDataSource] and keeps it as a singleton.
abstract final class UnifiedDataSourceFactory {
  static UnifiedDataSource? _instance;

  /// The data source from the last successful [create].
  ///
  /// Throws a [StateError] before [create], after [reset], and after a
  /// [create] that failed.
  static UnifiedDataSource get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
          'UnifiedDataSourceFactory has not been initialized. Call create() first.');
    }
    return inst;
  }

  /// Builds the data source [config] describes, opens it, and makes it the
  /// [instance].
  ///
  /// Disposes the previous [instance] first, if there is one.
  static Future<UnifiedDataSource> create(
      UnifiedDataSourceConfig config) async {
    final existing = _instance;
    if (existing != null) {
      _instance = null;
      await existing.dispose();
    }

    final dataSource = config.createDataSource();
    await dataSource.init();
    _instance = dataSource;
    return dataSource;
  }

  /// Disposes the [instance], if there is one, and forgets it.
  static Future<void> reset() async {
    final existing = _instance;
    _instance = null;
    await existing?.dispose();
  }
}
