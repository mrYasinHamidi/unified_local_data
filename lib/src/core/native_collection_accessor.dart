import 'query_builder.dart';

abstract interface class NativeCollectionAccessor<T> {
  Future<void> put(T item);

  Future<void> putAll(List<T> items);

  Future<T?> getById(dynamic id);

  Future<List<T>> getAll();

  Future<void> deleteById(dynamic id);

  Future<void> deleteAll();

  Future<int> count();

  Stream<List<T>> watchAll();

  Stream<T?> watchById(dynamic id);

  QueryBuilder<T> query();
}
