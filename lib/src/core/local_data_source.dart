import 'dart:async';

import 'data_model.dart';
import 'native_collection_accessor.dart';
import 'query_builder.dart';
import 'typedefs.dart';

abstract interface class LocalDataSource {
  Future<void> init();

  Future<void> dispose();

  Future<void> put<T>(String collection, String key, T value);

  Future<T?> get<T>(String collection, String key);

  Future<void> delete(String collection, String key);

  Future<void> clear(String collection);

  Future<List<T>> getAll<T>(String collection);

  Future<List<String>> getAllKeys(String collection);

  Future<bool> containsKey(String collection, String key);

  Future<int> count(String collection);

  Future<void> putObject<T>(
    String collection,
    String key,
    T value,
    DataModelAdapter<T> adapter,
  );

  Future<T?> getObject<T>(
    String collection,
    String key,
    DataModelAdapter<T> adapter,
  );

  Future<List<T>> getAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  );

  Future<void> putAll<T>(
    String collection,
    Map<String, T> entries,
  );

  Future<void> putAllObjects<T>(
    String collection,
    Map<String, T> entries,
    DataModelAdapter<T> adapter,
  );

  Stream<T?> watch<T>(String collection, String key);

  Stream<List<T>> watchAll<T>(String collection);

  Stream<List<T>> watchAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  );

  QueryBuilder<T> query<T>(
    String collection,
    DataModelAdapter<T> adapter,
  );

  Future<void> transaction(Future<void> Function() action);

  NativeCollectionAccessor<T> native<T>(String collection);
}
