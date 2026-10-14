import '../../core/unified_data_source.dart';
import '../../core/unified_data_source_config.dart';
import 'hive_data_source.dart';

/// The AES key that encrypts every Hive box the data source opens.
final class HiveEncryptionConfig {
  /// A 32-byte key, for example from `Hive.generateSecureKey()`.
  final List<int> key;

  /// Creates an encryption config with [key].
  const HiveEncryptionConfig({required this.key});
}

/// Configuration for the Hive engine, which stores each collection in its
/// own Hive box.
///
/// Works on every Flutter platform. On the web, boxes live in IndexedDB and
/// [directory] is ignored.
final class HiveDataSourceConfig extends UnifiedDataSourceConfig {
  /// Collections opened during `init()`, so their first read is fast.
  final List<String> preloadBoxes;

  /// Collections that `drop()` always covers, on top of the ones the data
  /// source has recorded itself. For collections written by 1.1.x or
  /// earlier, which were never recorded. Unlike [preloadBoxes], these aren't
  /// opened at `init()`.
  final List<String> collections;

  /// Encrypts every box, or null to store them in plain form.
  final HiveEncryptionConfig? encryption;

  /// Creates a Hive configuration that keeps its boxes in [directory].
  const HiveDataSourceConfig({
    required super.directory,
    this.preloadBoxes = const [],
    this.collections = const [],
    this.encryption,
  });

  @override
  UnifiedDataSource createDataSource() => HiveDataSource(config: this);
}
