import 'package:isar_community/isar.dart' show CollectionSchema;
import 'package:unified_local_data/engine.dart';

import 'isar_data_source.dart';

/// Configuration for the Isar engine. Pass it to
/// `UnifiedDataSourceFactory.create`.
///
/// The generic API keeps its entries in one internal Isar collection. Your
/// own `@collection` classes go in [schemas], for `native<T>()` and
/// `IsarDataSource.rawInstance`.
final class IsarDataSourceConfig extends UnifiedDataSourceConfig {
  /// The schemas of your own Isar collections, such as
  /// `[ProductEntitySchema]`. Leave it empty if you only use the generic API.
  final List<CollectionSchema<dynamic>> schemas;

  /// The most the database may grow to, in MiB.
  final int maxSizeMiB;

  /// Whether to enable the Isar Inspector, for debug builds.
  final bool inspector;

  /// Creates an Isar configuration that keeps its database in [directory].
  const IsarDataSourceConfig({
    required super.directory,
    this.schemas = const [],
    this.maxSizeMiB = 256,
    this.inspector = false,
  });

  @override
  UnifiedDataSource createDataSource() => IsarDataSource(config: this);
}
