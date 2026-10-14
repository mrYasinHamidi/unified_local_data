@TestOn('vm')
library;

import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_local_data/unified_local_data.dart';

import 'support/operations.dart';

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

    test('removes the empty collection when not opened in this run', () async {
      var db = await start();
      await db.put<String>('', 'user', 'u1');

      db = await restart();
      await db.drop();

      db = await restart();
      expect(await db.get<String>('', 'user'), isNull);
    });

    test('with a collection removes it when not opened in this run', () async {
      var db = await start();
      await db.put<int>('a', 'k', 1);
      await db.put<int>('b', 'k', 2);

      db = await restart();
      await db.drop(collection: 'a');

      expect(boxFile('a').existsSync(), isFalse);
      expect(await db.get<int>('b', 'k'), 2);
    });

    test('matches collection names regardless of case', () async {
      var db = await start();
      await db.put<String>('Mixed_Case', 'k', 'v');

      db = await restart();
      await db.drop();

      expect(boxFile('mixed_case').existsSync(), isFalse);
    });

    test('covers a collection written to again after an earlier drop',
        () async {
      var db = await start();
      await db.put<String>('settings', 'theme', 'dark');
      await db.drop();
      await db.put<String>('settings', 'theme', 'light');

      db = await restart();
      await db.drop();

      db = await restart();
      expect(await db.get<String>('settings', 'theme'), isNull);
    });

    test('covers a typed box opened with openTypedBox', () async {
      var db = await start();
      final box = await (db as HiveDataSource).openTypedBox<String>('typed');
      await box.put('k', 'v');

      db = await restart();
      await db.drop();

      expect(boxFile('typed').existsSync(), isFalse);
    });

    test('covers config.collections written before the registry existed',
        () async {
      // A box from 1.1.x: written straight through Hive, never recorded.
      Hive.init(dir.path);
      final legacy = await Hive.openBox<dynamic>('legacy');
      await legacy.put('k', 'v');
      await legacy.close();

      final db = await UnifiedDataSourceFactory.create(
        UnifiedDataSourceConfig.hive(
          directory: dir.path,
          collections: ['legacy'],
        ),
      );
      expect(boxFile('legacy').existsSync(), isTrue);
      await db.drop();

      expect(boxFile('legacy').existsSync(), isFalse);
    });

    test('throws before init()', () {
      final db = HiveDataSource(
        config: HiveDataSourceConfig(directory: dir.path),
      );
      expect(db.drop(), throwsA(isA<DataSourceNotInitializedException>()));
    });
  });

  group('maps and lists after a restart', () {
    test('a map reads back as Map<dynamic, dynamic>', () async {
      var db = await start();
      await db.put<Map<String, dynamic>>('maps', 'm', {'a': 1});
      // Same run: Hive hands back the object it holds in memory.
      expect(await db.get<Map<String, dynamic>>('maps', 'm'), {'a': 1});

      db = await restart();
      expect(await db.get<Map<dynamic, dynamic>>('maps', 'm'), {'a': 1});
      await expectLater(
        db.get<Map<String, dynamic>>('maps', 'm'),
        throwsA(isA<DataSourceReadException>()),
      );
    });

    test('a list of strings reads back as List<String>', () async {
      var db = await start();
      await db.put<List<String>>('lists', 'l', ['a', 'b']);

      db = await restart();
      expect(await db.get<List<String>>('lists', 'l'), ['a', 'b']);
      expect(await db.get<List<dynamic>>('lists', 'l'), ['a', 'b']);
    });

    test('an object round-trips through putObject and getObject', () async {
      final adapter = DataModelAdapter<Map<String, dynamic>>(
        fromJson: (json) => json,
        toJson: (map) => map,
      );
      var db = await start();
      await db.putObject('maps', 'o', {'a': 1}, adapter);

      db = await restart();
      expect(await db.getObject('maps', 'o', adapter), {'a': 1});
    });
  });

  group('every operation reports failures as LocalDataSourceException', () {
    // Hive asserts that box names are at most 255 characters, so every
    // operation on this collection fails when it opens the box.
    defineFailureTests(start, 'x' * 256);

    test('drop throws DataSourceWriteException', () async {
      final db = await start();
      // The registry only ever holds collection names, so drop() can't
      // read an int key.
      await Hive.box<dynamic>(HiveDataSource.registryBoxName).put(1, true);

      await expectLater(db.drop(), throwsA(isA<DataSourceWriteException>()));
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
