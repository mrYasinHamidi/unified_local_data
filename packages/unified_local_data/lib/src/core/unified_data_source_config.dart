import '../engines/hive/hive_config.dart';
import 'unified_data_source.dart';

/// Which engine a [UnifiedDataSource] uses, and how.
///
/// Pass one to `UnifiedDataSourceFactory.create`. Each engine has its own
/// subclass, which builds that engine's data source in [createDataSource]:
/// [HiveDataSourceConfig] here, and `IsarDataSourceConfig` in the
/// `unified_local_data_isar` package. To plug in an engine of your own,
/// extend this class.
abstract class UnifiedDataSourceConfig {
  /// Where the engine keeps its files. Engines that don't use one ignore it,
  /// as Hive does on the web.
  final String directory;

  /// Creates a configuration that keeps its files in [directory].
  const UnifiedDataSourceConfig({required this.directory});

  /// A configuration for the Hive engine. See [HiveDataSourceConfig] for the
  /// options.
  factory UnifiedDataSourceConfig.hive({
    required String directory,
    List<String> preloadBoxes,
    List<String> collections,
    HiveEncryptionConfig? encryption,
  }) = HiveDataSourceConfig;

  /// Creates the data source this configuration describes, without opening
  /// it. `UnifiedDataSourceFactory.create` calls [UnifiedDataSource.init] on
  /// the result.
  UnifiedDataSource createDataSource();
}
