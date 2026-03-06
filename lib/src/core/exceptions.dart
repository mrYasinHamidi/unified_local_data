sealed class LocalDataSourceException implements Exception {
  final String message;
  final Object? cause;

  const LocalDataSourceException(this.message, [this.cause]);

  @override
  String toString() => '[32m$runtimeType: $message${cause != null ? ' ($cause)' : ''}[0m';
}

final class DataSourceNotInitializedException extends LocalDataSourceException {
  const DataSourceNotInitializedException()
      : super('LocalDataSource has not been initialized. Call init() first.');
}

final class DataNotFoundException extends LocalDataSourceException {
  const DataNotFoundException(super.message);
}

final class DataSourceWriteException extends LocalDataSourceException {
  const DataSourceWriteException(super.message, [super.cause]);
}

final class DataSourceReadException extends LocalDataSourceException {
  const DataSourceReadException(super.message, [super.cause]);
}

final class UnsupportedOperationException extends LocalDataSourceException {
  const UnsupportedOperationException(super.message);
}
