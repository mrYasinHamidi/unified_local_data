import 'typedefs.dart';

/// A chainable query over the objects of one collection.
///
/// The filtering methods return the same builder, so calls chain. Nothing
/// runs until [findAll], [findFirst], [count] or [watch].
abstract interface class QueryBuilder<T> {
  /// Keeps only the objects for which [clause] returns true. Several calls
  /// combine with AND.
  QueryBuilder<T> where(WhereClause<T> clause);

  /// Orders the results with [comparator], replacing any earlier order.
  QueryBuilder<T> sortBy(SortComparator<T> comparator);

  /// Returns at most [count] results.
  QueryBuilder<T> limit(int count);

  /// Skips the first [start] results.
  QueryBuilder<T> offset(int start);

  /// Runs the query and returns every result.
  Future<List<T>> findAll();

  /// Runs the query and returns the first result, or null if there is none.
  Future<T?> findFirst();

  /// Runs the query and returns the number of results.
  Future<int> count();

  /// Deletes the results, where the engine supports it.
  Future<bool> deleteAll();

  /// Emits the results now, and again whenever the collection changes.
  Stream<List<T>> watch();
}

/// A [QueryBuilder] that loads every object and filters, sorts and pages
/// them in memory.
///
/// For engines without a query language of their own. [deleteAll] isn't
/// supported and throws an [UnsupportedError].
final class InMemoryQueryBuilder<T> implements QueryBuilder<T> {
  final Future<List<T>> Function() _fetcher;
  final Stream<List<T>> Function() _watcher;
  final List<WhereClause<T>> _filters = [];
  SortComparator<T>? _sorter;
  int? _limit;
  int? _offset;

  /// Creates a builder that loads the objects with [fetcher] and watches
  /// them with [watcher].
  InMemoryQueryBuilder({
    required Future<List<T>> Function() fetcher,
    required Stream<List<T>> Function() watcher,
  })  : _fetcher = fetcher,
        _watcher = watcher;

  @override
  QueryBuilder<T> where(WhereClause<T> clause) {
    _filters.add(clause);
    return this;
  }

  @override
  QueryBuilder<T> sortBy(SortComparator<T> comparator) {
    _sorter = comparator;
    return this;
  }

  @override
  QueryBuilder<T> limit(int count) {
    _limit = count;
    return this;
  }

  @override
  QueryBuilder<T> offset(int start) {
    _offset = start;
    return this;
  }

  List<T> _applyPipeline(List<T> items) {
    var result = List<T>.of(items);

    for (final filter in _filters) {
      result = result.where(filter).toList();
    }

    if (_sorter != null) {
      result.sort(_sorter);
    }

    if (_offset != null) {
      result = result.skip(_offset!).toList();
    }

    if (_limit != null) {
      result = result.take(_limit!).toList();
    }

    return result;
  }

  @override
  Future<List<T>> findAll() async {
    final items = await _fetcher();
    return _applyPipeline(items);
  }

  @override
  Future<T?> findFirst() async {
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  @override
  Future<int> count() async {
    final results = await findAll();
    return results.length;
  }

  @override
  Future<bool> deleteAll() async {
    throw UnsupportedError(
        'deleteAll via InMemoryQueryBuilder is not supported.');
  }

  @override
  Stream<List<T>> watch() {
    return _watcher().map(_applyPipeline);
  }
}
