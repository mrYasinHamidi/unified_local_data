/// A JSON object.
typedef JsonMap = Map<String, dynamic>;

/// Builds a [T] from a JSON object.
typedef FromJson<T> = T Function(JsonMap json);

/// Turns a [T] into a JSON object.
typedef ToJson<T> = JsonMap Function(T object);

/// Whether [item] belongs in a query's results.
typedef WhereClause<T> = bool Function(T item);

/// Orders two query results, the way [Comparator] does.
typedef SortComparator<T> = int Function(T a, T b);
