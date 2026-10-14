@TestOn('vm')
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_local_data_isar/src/isar_kv_entry.dart';
import 'package:unified_local_data_isar/unified_local_data_isar.dart';

import 'support/operations.dart';

/// Finds the host's Isar library inside the resolved
/// `isar_community_flutter_libs` package, so nothing is downloaded.
String? isarLibraryPath() {
  final config = File('.dart_tool/package_config.json').absolute;
  if (!config.existsSync()) return null;

  final packages = (jsonDecode(config.readAsStringSync()) as Map)['packages']
      as List<dynamic>;
  final libs = packages.cast<Map<String, dynamic>>().where(
        (p) => p['name'] == 'isar_community_flutter_libs',
      );
  if (libs.isEmpty) return null;

  final rootUri = libs.first['rootUri'] as String;
  final root =
      config.parent.uri.resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
  final relative = switch (Abi.current()) {
    Abi.windowsX64 => 'windows/libisar.dll',
    Abi.linuxX64 => 'linux/libisar.so',
    Abi.macosArm64 || Abi.macosX64 => 'macos/libisar.dylib',
    _ => null,
  };
  if (relative == null) return null;

  final library = File.fromUri(root.resolve(relative));
  return library.existsSync() ? library.path : null;
}

void main() {
  final libraryPath = isarLibraryPath();
  if (libraryPath == null) {
    test('Isar', () {}, skip: 'No Isar library for this host.');
    return;
  }

  late Directory dir;

  Future<UnifiedDataSource> start() => UnifiedDataSourceFactory.create(
        IsarDataSourceConfig(directory: dir.path),
      );

  setUpAll(() async {
    await Isar.initializeIsarCore(libraries: {Abi.current(): libraryPath});
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('uld_isar_test_');
  });

  tearDown(() async {
    await UnifiedDataSourceFactory.reset();
    await dir.delete(recursive: true);
  });

  group('transaction()', () {
    test('commits every write in the action together', () async {
      final db = await start();
      await db.put<int>('c', 'a', 1);

      await db.transaction(() async {
        await db.put<int>('c', 'b', 2);
        await db.putAll<int>('c', {'c': 3, 'd': 4});
        await db.delete('c', 'a');
        expect(await db.get<int>('c', 'b'), 2);
      });

      expect(await db.get<int>('c', 'a'), isNull);
      expect(await db.getAll<int>('c'), unorderedEquals([2, 3, 4]));
    });

    test('rolls back every write when the action throws', () async {
      final db = await start();
      await db.put<int>('c', 'a', 1);

      await expectLater(
        db.transaction(() async {
          await db.put<int>('c', 'b', 2);
          await db.clear('c');
          throw StateError('abort');
        }),
        throwsStateError,
      );

      expect(await db.get<int>('c', 'a'), 1);
      expect(await db.get<int>('c', 'b'), isNull);
    });

    test('joins a transaction already running', () async {
      final db = await start();

      await db.transaction(() async {
        await db.transaction(() => db.put<int>('c', 'a', 1));
        await db.drop(collection: 'other');
      });

      expect(await db.get<int>('c', 'a'), 1);
    });

    test('includes writes through native()', () async {
      final db = await start();
      final kv = db.native<IsarKvEntry>('kv');

      await expectLater(
        db.transaction(() async {
          await kv.put(IsarKvEntry()
            ..compositeKey = 'c::a'
            ..collection = 'c'
            ..key = 'a'
            ..value = '1');
          throw StateError('abort');
        }),
        throwsStateError,
      );

      expect(await kv.count(), 0);
    });
  });

  group('drop()', () {
    test('empties the whole database', () async {
      final db = await start();
      await db.put<int>('a', 'k', 1);
      await db.put<int>('b', 'k', 2);

      await db.drop();

      expect(await db.get<int>('a', 'k'), isNull);
      expect(await db.get<int>('b', 'k'), isNull);
    });

    test('with a collection removes only that collection', () async {
      final db = await start();
      await db.put<int>('a', 'k', 1);
      await db.put<int>('b', 'k', 2);

      await db.drop(collection: 'a');

      expect(await db.get<int>('a', 'k'), isNull);
      expect(await db.get<int>('b', 'k'), 2);
    });
  });

  group('maps and lists', () {
    test('a map reads back as Map<String, dynamic>', () async {
      final db = await start();
      await db.put<Map<String, dynamic>>('maps', 'm', {'a': 1});

      expect(await db.get<Map<String, dynamic>>('maps', 'm'), {'a': 1});
    });

    test('a list of strings reads back as List<dynamic>', () async {
      final db = await start();
      await db.put<List<String>>('lists', 'l', ['a', 'b']);

      expect(await db.get<List<dynamic>>('lists', 'l'), ['a', 'b']);
      await expectLater(
        db.get<List<String>>('lists', 'l'),
        throwsA(isA<DataSourceReadException>()),
      );
    });
  });

  group('every operation reports failures as LocalDataSourceException', () {
    // Closing the Isar instance underneath the data source makes every
    // operation fail inside Isar.
    defineFailureTests(() async {
      final db = await start();
      await (db as IsarDataSource).rawInstance.close();
      return db;
    }, 'c');

    test('drop throws DataSourceWriteException', () async {
      final db = await start();
      await (db as IsarDataSource).rawInstance.close();

      await expectLater(db.drop(), throwsA(isA<DataSourceWriteException>()));
    });

    test('drop throws before init()', () {
      final db = IsarDataSource(
        config: IsarDataSourceConfig(directory: dir.path),
      );
      expect(db.drop(), throwsA(isA<DataSourceNotInitializedException>()));
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
        db.put<Object>('msg_coll', 'msg_key', Object()),
        throwsA(isA<DataSourceWriteException>().having(
          (e) => e.message,
          'message',
          allOf(contains('msg_key'), contains('msg_coll')),
        )),
      );
    });
  });
}
