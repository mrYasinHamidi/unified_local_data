import 'dart:async';

import 'exceptions.dart';

/// Runs a read, reporting any failure that isn't already a
/// [LocalDataSourceException] as a [DataSourceReadException] with [message].
Future<T> guardRead<T>(String message, Future<T> Function() action) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    if (error is LocalDataSourceException) rethrow;
    Error.throwWithStackTrace(
      DataSourceReadException(message, error),
      stackTrace,
    );
  }
}

/// Runs a write or a delete, reporting any failure that isn't already a
/// [LocalDataSourceException] as a [DataSourceWriteException] with [message].
Future<T> guardWrite<T>(String message, Future<T> Function() action) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    if (error is LocalDataSourceException) rethrow;
    Error.throwWithStackTrace(
      DataSourceWriteException(message, error),
      stackTrace,
    );
  }
}

/// Opens a watch stream, reporting a failure to open it, and every error it
/// emits, the way [guardRead] does.
Stream<T> guardStream<T>(String message, Stream<T> Function() open) {
  Object wrap(Object error) => error is LocalDataSourceException
      ? error
      : DataSourceReadException(message, error);

  try {
    return open().transform(StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) =>
          sink.addError(wrap(error), stackTrace),
    ));
  } catch (error, stackTrace) {
    return Stream.error(wrap(error), stackTrace);
  }
}
