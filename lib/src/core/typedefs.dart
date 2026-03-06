typedef JsonMap = Map<String, dynamic>;
typedef FromJson<T> = T Function(JsonMap json);
typedef ToJson<T> = JsonMap Function(T object);
typedef WhereClause<T> = bool Function(T item);
typedef SortComparator<T> = int Function(T a, T b);
