@TestOn('vm')
library;

import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_local_data/unified_local_data.dart';

void main() {
  late Directory dir;

  Future<UnifiedDataSource> start() => UnifiedDataSourceFactory.create(
        UnifiedDataSourceConfig.hive(directory: dir.path),
      );

  /// Restarts the source the way an app restart does.
  Future<UnifiedDataSource> restart() async {
    await UnifiedDataSourceFactory.reset();
    return start();
  }

  File boxFile(String name) =>
      File('${dir.path}${Platform.pathSeparator}$name.hive');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('uld_hive_test_');
  });

  tearDown(() async {
    await UnifiedDataSourceFactory.reset();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  group('drop()', () {
    test('removes a collection not opened in this run', () async {
      var db = await start();
      await db.put<String>('map_memory', 'camera', 'saved');
      await db.put<String>('auth', 'token', 'abc');

      db = await restart();
      expect(await db.get<String>('auth', 'token'), 'abc');
      await db.drop();

      expect(boxFile('map_memory').existsSync(), isFalse);
      db = await restart();
      expect(await db.get<String>('map_memory', 'camera'), isNull);
      expect(await db.get<String>('auth', 'token'), isNull);
    });

    test('removes a collection opened in this run', () async {
      final db = await start();
      await db.put<String>('settings', 'theme', 'dark');
      await db.drop();

      expect(boxFile('settings').existsSync(), isFalse);
      expect(await db.get<String>('settings', 'theme'), isNull);
    });

    test('with a collection removes only that collection', () async {
      var db = await start();
      await db.put<int>('a', 'k', 1);
      await db.put<int>('b', 'k', 2);
      await db.drop(collection: 'a');

      expect(await db.get<int>('a', 'k'), isNull);
      expect(await db.get<int>('b', 'k'), 2);

      db = await restart();
      expect(await db.get<int>('a', 'k'), isNull);
      expect(await db.get<int>('b', 'k'), 2);
    });

    test('leaves the collection usable', () async {
      final db = await start();
      await db.put<String>('settings', 'theme', 'dark');
      await db.drop();
      await db.put<String>('settings', 'theme', 'light');
      expect(await db.get<String>('settings', 'theme'), 'light');

      await db.drop(collection: 'settings');
      await db.put<String>('settings', 'theme', 'system');
      expect(await db.get<String>('settings', 'theme'), 'system');
    });

    test('handles the empty collection name', () async {
      var db = await start();
      await db.put<String>('', 'user', 'u1');
      expect(await db.get<String>('', 'user'), 'u1');

      db = await restart();
      expect(await db.get<String>('', 'user'), 'u1');
      await db.drop();
      expect(await db.get<String>('', 'user'), isNull);
    });
  });

  group('errors', () {
    test('a failed get names the key and the collection', () async {
      final db = await start();
      await db.put<int>('msg_coll', 'msg_key', 1);

      await expectLater(
        db.get<String>('msg_coll', 'msg_key'),
        throwsA(isA<DataSourceReadException>().having(
          (e) => e.message,
          'message',
          allOf(contains('msg_key'), contains('msg_coll')),
        )),
      );
    });

    test('a failed put names the key and the collection', () async {
      final db = await start();

      await expectLater(
        db.put<Object>('msg_coll', 'msg_key', _Unstorable()),
        throwsA(isA<DataSourceWriteException>().having(
          (e) => e.message,
          'message',
          allOf(contains('msg_key'), contains('msg_coll')),
        )),
      );
    });
  });
}

/// A type with no Hive adapter, so Hive can't write it.
class _Unstorable {}
