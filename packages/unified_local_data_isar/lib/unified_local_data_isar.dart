/// The Isar engine for `unified_local_data`.
///
/// Pass an [IsarDataSourceConfig] to [UnifiedDataSourceFactory.create], then
/// use the [UnifiedDataSource] API as with any other engine. Re-exports
/// `package:unified_local_data/unified_local_data.dart`, so this one import
/// is enough.
library;

export 'package:unified_local_data/unified_local_data.dart';

export 'src/isar_config.dart';
export 'src/isar_data_source.dart';
