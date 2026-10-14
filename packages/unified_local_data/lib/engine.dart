/// Building blocks for implementing a [UnifiedDataSource] engine.
///
/// Exports everything in `package:unified_local_data/unified_local_data.dart`
/// plus helpers that make an engine behave like the built-in ones:
///
/// * [guardRead], [guardWrite] and [guardStream] report the engine's errors
///   as [DataSourceReadException] and [DataSourceWriteException].
/// * [InMemoryQueryBuilder] answers [UnifiedDataSource.query] for engines
///   without a query language of their own.
///
/// An engine has two parts: a [UnifiedDataSource] implementation, and a
/// [UnifiedDataSourceConfig] subclass whose
/// [UnifiedDataSourceConfig.createDataSource] builds it. Pass the config to
/// [UnifiedDataSourceFactory.create] like any other.
library;

export 'unified_local_data.dart';
export 'src/core/guard.dart';
export 'src/core/query_builder.dart' show InMemoryQueryBuilder;
