import 'dart:async';

import 'package:isar_community/isar.dart';

import '../../core/native_collection_accessor.dart';
import '../../core/query_builder.dart' as core;

final class IsarNativeAccessor<T> implements NativeCollectionAccessor<T> {
  final Isar _isar;
  final IsarCollection<T> _collection;

  IsarNativeAccessor(this._isar, this._collection);

  @override
  Future<void> put(T item) async {
    await _isar.writeTxn(() => _collection.put(item));
  }

  @override
  Future<void> putAll(List<T> items) async {
    await _isar.writeTxn(() => _collection.putAll(items));
  }

  @override
  Future<T?> getById(dynamic id) async {
    return _collection.get(id as int);
  }

  @override
  Future<List<T>> getAll() async {
    return _collection.where().findAll();
  }

  @override
  Future<void> deleteById(dynamic id) async {
    await _isar.writeTxn(() => _collection.delete(id as int));
  }

  @override
  Future<void> deleteAll() async {
    await _isar.writeTxn(() => _collection.clear());
  }

  @override
  Future<int> count() async {
    return _collection.count();
  }

  @override
  Stream<List<T>> watchAll() {
    return _collection.where().watch(fireImmediately: true);
  }

  @override
  Stream<T?> watchById(dynamic id) {
    return _isar.collection<T>().watchObject(id as int, fireImmediately: true);
  }

  @override
  core.QueryBuilder<T> query() {
    return core.InMemoryQueryBuilder<T>(
      fetcher: () => _collection.where().findAll(),
      watcher: () => _collection.where().watch(fireImmediately: true),
    );
  }
}
