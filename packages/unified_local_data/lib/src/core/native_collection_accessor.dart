import 'query_builder.dart';

/// Direct access to one collection through the engine's own types, returned
/// by `UnifiedDataSource.native`.
///
/// Unlike the rest of the API, it throws the engine's own errors.
abstract interface class NativeCollectionAccessor<T> {
  /// Stores [item].
  Future<void> put(T item);

  /// Stores every item in [items].
  Future<void> putAll(List<T> items);

  /// Returns the item with [id], or null if there is none.
  Future<T?> getById(dynamic id);

  /// Returns every item.
  Future<List<T>> getAll();

  /// Removes the item with [id].
  Future<void> deleteById(dynamic id);

  /// Removes every item.
  Future<void> deleteAll();

  /// The number of items.
  Future<int> count();

  /// Emits every item now, and again whenever the collection changes.
  Stream<List<T>> watchAll();

  /// Emits the item with [id] now, and again whenever it changes.
  Stream<T?> watchById(dynamic id);

  /// Starts a query over the items.
  QueryBuilder<T> query();
}
