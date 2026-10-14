/// Engine-agnostic local storage for Flutter.
///
/// Create a data source with [UnifiedDataSourceFactory.create] and a config,
/// such as [UnifiedDataSourceConfig.hive], then use the [UnifiedDataSource]
/// API: the same calls work on every engine. For Isar, add the
/// `unified_local_data_isar` package. To write an engine of your own, see
/// `package:unified_local_data/engine.dart`.
library;

export 'src/core/unified_data_source.dart';
export 'src/core/unified_data_source_config.dart';
export 'src/core/unified_data_source_factory.dart';
export 'src/core/data_model.dart';
export 'src/core/native_collection_accessor.dart';
export 'src/core/query_builder.dart' show QueryBuilder;
export 'src/core/exceptions.dart';
export 'src/core/typedefs.dart';

export 'src/engines/hive/hive_config.dart';
export 'src/engines/hive/hive_data_source.dart';

export 'src/extensions/stream_extensions.dart';
