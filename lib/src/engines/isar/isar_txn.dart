import 'dart:async';

import 'package:isar_community/isar.dart';

/// Zone key under which [writeTxn] stores the Isar instance whose write
/// transaction is running.
const Symbol _transactionKey = #unifiedLocalDataIsarWriteTxn;

/// Runs [action] in a write transaction on [isar], or as part of the one
/// that's already running. Isar doesn't nest transactions, so the writes made
/// inside `IsarDataSource.transaction` have to join it.
Future<T> writeTxn<T>(Isar isar, Future<T> Function() action) {
  if (identical(Zone.current[_transactionKey], isar)) return action();
  return isar.writeTxn(
    () => runZoned(action, zoneValues: {_transactionKey: isar}),
  );
}
