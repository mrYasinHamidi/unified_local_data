import 'typedefs.dart';

abstract interface class QueryBuilder<T> {
  QueryBuilder<T> where(WhereClause<T> clause);
  QueryBuilder<T> sortBy(SortComparator<T> comparator);
  QueryBuilder<T> limit(int count);
  QueryBuilder<T> offset(int start);
  Future<List<T>> findAll();
  Future<T?> findFirst();
  Future<int> count();
  Future<bool> deleteAll();
  Stream<List<T>> watch();
}

final class InMemoryQueryBuilder<T> implements QueryBuilder<T> {
  final Future<List<T>> Function() _fetcher;
  final Stream<List<T>> Function() _watcher;
  final List<WhereClause<T>> _filters = [];
  SortComparator<T>? _sorter;
  int? _limit;
  int? _offset;

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
    throw UnsupportedError('deleteAll via InMemoryQueryBuilder is not supported.');
  }

  @override
  Stream<List<T>> watch() {
    return _watcher().map(_applyPipeline);
  }
}
