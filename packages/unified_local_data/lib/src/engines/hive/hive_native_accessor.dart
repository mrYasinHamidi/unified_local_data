import 'dart:async';

import 'package:hive_ce/hive_ce.dart';

import '../../core/native_collection_accessor.dart';
import '../../core/query_builder.dart';

final class HiveNativeAccessor<T> implements NativeCollectionAccessor<T> {
  final Box<T> _box;

  HiveNativeAccessor(this._box);

  @override
  Future<void> put(T item) async {
    if (item is HiveObject && item.key != null) {
      await _box.put(item.key, item);
      return;
    }
    await _box.add(item);
  }

  @override
  Future<void> putAll(List<T> items) async {
    await _box.addAll(items);
  }

  @override
  Future<T?> getById(dynamic id) async {
    return _box.get(id);
  }

  @override
  Future<List<T>> getAll() async {
    return _box.values.toList();
  }

  @override
  Future<void> deleteById(dynamic id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    await _box.clear();
  }

  @override
  Future<int> count() async {
    return _box.length;
  }

  @override
  Stream<List<T>> watchAll() async* {
    yield _box.values.toList();
    yield* _box.watch().map((_) => _box.values.toList());
  }

  @override
  Stream<T?> watchById(dynamic id) async* {
    yield _box.get(id);
    yield* _box.watch(key: id).map((event) => event.value as T?);
  }

  @override
  QueryBuilder<T> query() {
    return InMemoryQueryBuilder<T>(
      fetcher: () async => _box.values.toList(),
      watcher: () => watchAll(),
    );
  }
}
