@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:unified_local_data/unified_local_data.dart';
import 'package:web/web.dart' as web;

/// Opens a raw IndexedDB connection that hive_ce knows nothing about, the way
/// another tab of the same origin would.
Future<web.IDBDatabase> openRawConnection(String name) {
  final completer = Completer<web.IDBDatabase>();
  final request = web.window.indexedDB.open(name, 1);
  request.onsuccess = ((web.Event _) {
    completer.complete(request.result as web.IDBDatabase);
  }).toJS;
  request.onerror = ((web.Event _) {
    completer.completeError(StateError('Could not open $name'));
  }).toJS;
  return completer.future;
}

void main() {
  web.IDBDatabase? rawConnection;

  tearDown(() async {
    rawConnection?.close();
    rawConnection = null;
    await UnifiedDataSourceFactory.reset();
  });

  test('drop() finishes while another connection is open', () async {
    final db = await UnifiedDataSourceFactory.create(
      UnifiedDataSourceConfig.hive(directory: 'uld_web_test'),
    );
    await db.put<String>('web_drop', 'k', 'v');
    rawConnection = await openRawConnection('web_drop');

    await db.drop().timeout(const Duration(seconds: 5));

    expect(await db.get<String>('web_drop', 'k'), isNull);
  });

  test('drop(collection:) finishes while another connection is open', () async {
    final db = await UnifiedDataSourceFactory.create(
      UnifiedDataSourceConfig.hive(directory: 'uld_web_test'),
    );
    await db.put<String>('web_drop_one', 'k', 'v');
    await db.put<String>('web_keep', 'k', 'v');
    rawConnection = await openRawConnection('web_drop_one');

    await db
        .drop(collection: 'web_drop_one')
        .timeout(const Duration(seconds: 5));

    expect(await db.get<String>('web_drop_one', 'k'), isNull);
    expect(await db.get<String>('web_keep', 'k'), 'v');
  });

  test('drop() empties a collection not opened in this run', () async {
    const config = HiveDataSourceConfig(directory: 'uld_web_test');
    await UnifiedDataSourceFactory.create(config)
        .then((db) => db.put<String>('web_unopened', 'k', 'v'));
    await UnifiedDataSourceFactory.reset();

    final db = await UnifiedDataSourceFactory.create(config);
    rawConnection = await openRawConnection('web_unopened');
    await db.drop().timeout(const Duration(seconds: 5));

    expect(await db.get<String>('web_unopened', 'k'), isNull);
  });
}
