## 1.1.2

* Fixed a Flutter Web build failure (`The integer literal ... can't be represented exactly in JavaScript`) in the generated `IsarKvEntry` schema by rounding its schema/index ids to exactly-representable values. Any app depending on this package failed `flutter build web` before this fix, even if it never used the Isar engine.

## 1.1.1

* Fixed `repository` and `issue_tracker` links, which still pointed at the pre-rename GitHub path.
* Formatted the package with `dart format`. No behavior changes.

## 1.1.0

* Added `deleteAll(collection, keys)` for removing multiple keys in one call.
* Added `drop({collection})` to delete a single collection from disk, or the entire database when no collection is given.
* Added `watchObject<T>(collection, key, adapter)` to watch a single key as a typed object.

## 1.0.0

* Initial release of `unified_local_data`.
* Universal, engine-agnostic local database abstraction layer for Flutter.
* Support for [Hive CE](https://pub.dev/packages/hive_ce) and [Isar Community](https://pub.dev/packages/isar_community) engines.
* Unified `LocalDataSource` interface for primitives, complex objects, batch operations, reactive streams, query builder, and transactions.
* `NativeCollectionAccessor` API for direct engine-level access when needed.
* `LocalDataSourceFactory` for simple engine initialization and configuration.
* Stream extensions for reactive data patterns.
