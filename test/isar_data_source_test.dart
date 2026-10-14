@TestOn('vm')
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_local_data/unified_local_data.dart';

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
        UnifiedDataSourceConfig.isar(directory: dir.path, schemas: []),
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
