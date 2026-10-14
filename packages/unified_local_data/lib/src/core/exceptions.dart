/// The base of every exception a `UnifiedDataSource` throws.
sealed class LocalDataSourceException implements Exception {
  /// What failed, naming the key and the collection where there is one.
  final String message;

  /// The engine's own error, if this exception wraps one.
  final Object? cause;

  /// Creates an exception with [message] and an optional [cause].
  const LocalDataSourceException(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

/// Thrown when a data source is used before `init()` or after `dispose()`.
final class DataSourceNotInitializedException extends LocalDataSourceException {
  /// Creates the exception.
  const DataSourceNotInitializedException()
      : super('LocalDataSource has not been initialized. Call init() first.');
}

/// Thrown when requested data doesn't exist.
final class DataNotFoundException extends LocalDataSourceException {
  /// Creates the exception with [message].
  const DataNotFoundException(super.message);
}

/// Thrown when a write, a delete, `clear` or `drop` fails.
final class DataSourceWriteException extends LocalDataSourceException {
  /// Creates the exception with [message] and the engine's error as [cause].
  const DataSourceWriteException(super.message, [super.cause]);
}

/// Thrown when a read fails, including when a stored value isn't of the
/// requested type. Watch streams emit it as an error.
final class DataSourceReadException extends LocalDataSourceException {
  /// Creates the exception with [message] and the engine's error as [cause].
  const DataSourceReadException(super.message, [super.cause]);
}

/// Thrown when the engine can't do what was asked, such as returning a
/// native accessor for a box that isn't open.
final class UnsupportedOperationException extends LocalDataSourceException {
  /// Creates the exception with [message].
  const UnsupportedOperationException(super.message);
}
