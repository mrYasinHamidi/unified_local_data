import 'package:flutter_test/flutter_test.dart';
import 'package:unified_local_data/unified_local_data.dart';

final _adapter = DataModelAdapter<Map<String, dynamic>>(
  fromJson: (json) => json,
  toJson: (map) => map,
);

/// Defines one test per public operation, each expecting the operation on
/// [collection] to fail with the exception type the plan promises: reads
/// throw [DataSourceReadException], writes and deletes throw
/// [DataSourceWriteException], and watch streams emit a
/// [DataSourceReadException]. [open] returns a data source on which every
/// operation on [collection] fails.
void defineFailureTests(
  Future<UnifiedDataSource> Function() open,
  String collection,
) {
  final reads = <String, Future<Object?> Function(UnifiedDataSource)>{
    'get': (db) => db.get<String>(collection, 'k'),
    'getAll': (db) => db.getAll<String>(collection),
    'getAllKeys': (db) => db.getAllKeys(collection),
    'containsKey': (db) => db.containsKey(collection, 'k'),
    'count': (db) => db.count(collection),
    'getObject': (db) => db.getObject(collection, 'k', _adapter),
    'getAllObjects': (db) => db.getAllObjects(collection, _adapter),
  };
  final writes = <String, Future<void> Function(UnifiedDataSource)>{
    'put': (db) => db.put<String>(collection, 'k', 'v'),
    'delete': (db) => db.delete(collection, 'k'),
    'deleteAll': (db) => db.deleteAll(collection, ['k']),
    'clear': (db) => db.clear(collection),
    'putObject': (db) => db.putObject(collection, 'k', {'a': 1}, _adapter),
    'putAll': (db) => db.putAll<String>(collection, {'k': 'v'}),
    'putAllObjects': (db) => db.putAllObjects(
          collection,
          {
            'k': {'a': 1}
          },
          _adapter,
        ),
  };
  final watches = <String, Stream<Object?> Function(UnifiedDataSource)>{
    'watch': (db) => db.watch<String>(collection, 'k'),
    'watchObject': (db) => db.watchObject(collection, 'k', _adapter),
    'watchAll': (db) => db.watchAll<String>(collection),
    'watchAllObjects': (db) => db.watchAllObjects(collection, _adapter),
  };

  for (final MapEntry(key: name, value: read) in reads.entries) {
    test('$name throws DataSourceReadException', () async {
      final db = await open();
      await expectLater(read(db), throwsA(isA<DataSourceReadException>()));
    });
  }
  for (final MapEntry(key: name, value: write) in writes.entries) {
    test('$name throws DataSourceWriteException', () async {
      final db = await open();
      await expectLater(write(db), throwsA(isA<DataSourceWriteException>()));
    });
  }
  for (final MapEntry(key: name, value: watch) in watches.entries) {
    test('$name emits DataSourceReadException', () async {
      final db = await open();
      await expectLater(
        watch(db).first,
        throwsA(isA<DataSourceReadException>()),
      );
    });
  }
}
