## 2.0.0

### Breaking changes

* The Isar engine moved to its own package, [`unified_local_data_isar`](https://pub.dev/packages/unified_local_data_isar). This package no longer depends on Isar, so apps that only use Hive stop shipping Isar's native library (about 1 MB per platform), and the package now supports the web on pub.dev.
  * Replace `UnifiedDataSourceConfig.isar(...)` with `IsarDataSourceConfig(...)` and import `package:unified_local_data_isar/unified_local_data_isar.dart`.
* Removed `DatabaseEngine` and `UnifiedDataSourceConfig.engine`.
* `UnifiedDataSourceConfig` subclasses implement `createDataSource()`, which builds the engine's data source. The factory calls it instead of matching on the config type, so any engine, including your own, can be created through `UnifiedDataSourceFactory.create`.

Hive-only apps need no code changes: bump the constraint to `^2.0.0`.

### Additions

* `package:unified_local_data/engine.dart`, for engine authors: the whole API plus `guardRead`, `guardWrite`, `guardStream` and `InMemoryQueryBuilder`.
* Documentation comments on the whole public API.

### Fixes

* If `UnifiedDataSourceFactory.create` fails, `instance` now throws instead of returning the previous, already disposed data source.

### Dependencies

* Removed `isar_community`, `isar_community_flutter_libs`, and the dev dependencies `isar_community_generator`, `hive_ce_generator` and `build_runner`.

## 1.2.1

### Fixes

* Isar: `transaction()` works. Every data source write opened its own Isar transaction, and Isar doesn't nest them, so any write inside `transaction()` failed. Writes inside it, including writes through `native<T>()` and a nested `transaction()`, now join the running transaction. If the action throws, all of its writes roll back.
* Isar: `drop()` with no collection works. It cleared the database outside a write transaction, which Isar refuses, so it always failed.

### Dependencies

* `isar_community` and `isar_community_flutter_libs` are `^3.4.1` again instead of exactly 3.4.1, which pub warned about. The generated schema now declares the Isar version the app resolves, so it compiles against any 3.x release from 3.4.1 on.

### Documentation

* The README uses the real API names (`UnifiedDataSourceFactory`, `UnifiedDataSourceConfig`, `UnifiedDataSource`, `package:unified_local_data/unified_local_data.dart`) instead of names that never existed.
* Corrected the Installation section, the architecture diagram, the folder structure, the transaction notes, and the guide to adding an engine. The package needs Flutter; the FAQ said it worked in pure Dart.

## 1.2.0

### Fixes

* Hive: `drop()` now covers every collection the data source has opened, not just the ones open in the current run. Before, a box written in an earlier run and not opened since survived a `drop()`. The engine records collection names in a reserved box, `_uld_collections`.
* Hive on the web: `drop()` and `drop(collection:)` empty the boxes instead of deleting their IndexedDB databases. A delete waited for every other connection to close, so with a second tab open it never finished, and the app's next start hung behind it.
* Isar: fixed `Isar.open` failing on every native platform with `Collection id is invalid`. 1.1.2 rounded the schema ids so web builds compile, but Isar checks each id against the hash of its name. The ids are now constant expressions that are exact on native and still compile for the web.
* Isar: the generated schema is regenerated for Isar 3.4.1, and Isar is pinned to that exact version. The schema asserts its Isar version, so with 1.1.2 any app that resolved Isar 3.4.x failed to compile in debug mode, even if it only used Hive.
* Exception messages name the key and the collection. They used to read literally `key=$key in $collection`.
* `toString()` of an exception is plain text, without ANSI colour codes.
* Every operation of both engines throws only `LocalDataSourceException` subtypes: `DataSourceReadException` for reads, `DataSourceWriteException` for writes, deletes and `drop`, with the engine's error as `cause`. Watch streams emit their errors the same way. Several operations used to let the engine's own error through.
* `drop()` on either engine throws `DataSourceNotInitializedException` before `init()`.

### Additions

* `HiveDataSourceConfig.collections` (also on `UnifiedDataSourceConfig.hive`): collections that `drop()` always covers. Use it for boxes written by an earlier version, which the registry has never seen.

### Dependencies

* Requires Dart 3.4 and Flutter 3.22, which hive_ce 2.21 already needed.
* hive_ce ^2.21.0; isar_community and isar_community_flutter_libs 3.4.1, exactly.
* Removed `hive_ce_flutter` and `meta`, which nothing imported. `path_provider` is now a dev dependency; only the example uses it.

### Documentation

* Lists and maps read back differently on Hive and Isar. The README now says to read lists as `List<dynamic>` and to store maps with `putObject` / `getObject`.

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
