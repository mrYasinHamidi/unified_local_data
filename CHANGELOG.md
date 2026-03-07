## 1.0.0

* Initial release of `unified_local_data`.
* Universal, engine-agnostic local database abstraction layer for Flutter.
* Support for [Hive CE](https://pub.dev/packages/hive_ce) and [Isar Community](https://pub.dev/packages/isar_community) engines.
* Unified `LocalDataSource` interface for primitives, complex objects, batch operations, reactive streams, query builder, and transactions.
* `NativeCollectionAccessor` API for direct engine-level access when needed.
* `LocalDataSourceFactory` for simple engine initialization and configuration.
* Stream extensions for reactive data patterns.
