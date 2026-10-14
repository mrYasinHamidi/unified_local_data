import 'dart:async';

import 'data_model.dart';
import 'exceptions.dart';
import 'native_collection_accessor.dart';
import 'query_builder.dart';

/// Local key-value storage that works the same on every engine.
///
/// Data lives in named collections, each holding values under string keys.
/// Get an instance from `UnifiedDataSourceFactory.create`, which also calls
/// [init].
///
/// Reads throw [DataSourceReadException] and writes throw
/// [DataSourceWriteException] when the engine fails; watch streams emit
/// [DataSourceReadException]. Every method throws
/// [DataSourceNotInitializedException] before [init].
abstract interface class UnifiedDataSource {
  /// Opens the engine. Calling it again on an open data source does nothing.
  Future<void> init();

  /// Closes the engine and releases its resources. Call [init] to use the
  /// data source again.
  Future<void> dispose();

  /// Stores [value] under [key] in [collection], replacing any value there.
  ///
  /// For primitives and lists of them. Store maps and other objects with
  /// [putObject].
  Future<void> put<T>(String collection, String key, T value);

  /// Returns the value under [key] in [collection], or null if there is none.
  ///
  /// Throws [DataSourceReadException] if the stored value isn't a [T].
  Future<T?> get<T>(String collection, String key);

  /// Removes [key] from [collection]. Does nothing if it isn't there.
  Future<void> delete(String collection, String key);

  /// Removes every key in [keys] from [collection].
  Future<void> deleteAll(String collection, List<String> keys);

  /// Removes [collection], or every collection when it is null.
  ///
  /// Covers collections the app hasn't opened since it started. Unlike
  /// [clear], it's meant for wiping storage, for example on logout.
  Future<void> drop({String? collection});

  /// Removes every entry in [collection] and keeps the collection.
  Future<void> clear(String collection);

  /// Returns every value in [collection].
  Future<List<T>> getAll<T>(String collection);

  /// Returns every key in [collection].
  Future<List<String>> getAllKeys(String collection);

  /// Whether [collection] has a value under [key].
  Future<bool> containsKey(String collection, String key);

  /// The number of entries in [collection].
  Future<int> count(String collection);

  /// Stores [value] under [key] in [collection] as JSON, using [adapter] to
  /// convert it.
  Future<void> putObject<T>(
    String collection,
    String key,
    T value,
    DataModelAdapter<T> adapter,
  );

  /// Returns the object under [key] in [collection], or null if there is
  /// none, using [adapter] to convert it from JSON.
  Future<T?> getObject<T>(
    String collection,
    String key,
    DataModelAdapter<T> adapter,
  );

  /// Returns every object in [collection], using [adapter] to convert them
  /// from JSON.
  Future<List<T>> getAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  );

  /// Stores every entry of [entries] in [collection].
  Future<void> putAll<T>(
    String collection,
    Map<String, T> entries,
  );

  /// Stores every entry of [entries] in [collection] as JSON, using [adapter]
  /// to convert the values.
  Future<void> putAllObjects<T>(
    String collection,
    Map<String, T> entries,
    DataModelAdapter<T> adapter,
  );

  /// Emits the value under [key] in [collection] now, and again whenever it
  /// changes. Emits null while there is no value.
  Stream<T?> watch<T>(String collection, String key);

  /// Emits the object under [key] in [collection] now, and again whenever it
  /// changes, using [adapter] to convert it. Emits null while there is none.
  Stream<T?> watchObject<T>(
    String collection,
    String key,
    DataModelAdapter<T> adapter,
  );

  /// Emits every value in [collection] now, and again whenever the
  /// collection changes.
  Stream<List<T>> watchAll<T>(String collection);

  /// Emits every object in [collection] now, and again whenever the
  /// collection changes, using [adapter] to convert them.
  Stream<List<T>> watchAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  );

  /// Starts a query over the objects in [collection], converted with
  /// [adapter].
  QueryBuilder<T> query<T>(
    String collection,
    DataModelAdapter<T> adapter,
  );

  /// Runs [action], as one transaction where the engine supports them.
  ///
  /// Whatever [action] throws reaches the caller unchanged. Engines without
  /// transactions run [action] as is, so a failure part-way leaves the
  /// earlier writes in place.
  Future<void> transaction(Future<void> Function() action);

  /// Direct access to [collection] through the engine's own types, such as
  /// Hive type adapters or Isar collections.
  NativeCollectionAccessor<T> native<T>(String collection);
}
