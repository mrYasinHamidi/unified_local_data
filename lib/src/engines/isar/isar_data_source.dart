import 'dart:async';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../core/data_model.dart';
import '../../core/exceptions.dart';
import '../../core/guard.dart';
import '../../core/unified_data_source.dart';
import '../../core/native_collection_accessor.dart';
import '../../core/query_builder.dart' as core;
import '../../core/typedefs.dart';
import 'isar_config.dart';
import 'isar_native_accessor.dart';
import 'isar_kv_entry.dart';

final class IsarDataSource implements UnifiedDataSource {
  final IsarDataSourceConfig config;
  Isar? _isar;
  bool _initialized = false;
  final Map<String, NativeCollectionAccessor<dynamic>> _nativeAccessors = {};

  IsarDataSource({required this.config});

  Isar get _db {
    final db = _isar;
    if (db == null) throw const DataSourceNotInitializedException();
    return db;
  }

  Isar get rawInstance {
    _ensureInitialized();
    return _db;
  }

  @override
  Future<void> init() async {
    if (_initialized) return;

    final schemas = <CollectionSchema<dynamic>>[
      IsarKvEntrySchema,
      ...config.schemas.cast<CollectionSchema<dynamic>>(),
    ];

    _isar = await guardRead(
      'Failed to open the database in "${config.directory}"',
      () => Isar.open(
        schemas,
        directory: config.directory,
        maxSizeMiB: config.maxSizeMiB,
        inspector: config.inspector,
      ),
    );

    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    final db = _isar;
    if (db != null && db.isOpen) {
      await guardWrite('Failed to close the database', db.close);
    }
    _isar = null;
    _nativeAccessors.clear();
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized || _isar == null) {
      throw const DataSourceNotInitializedException();
    }
  }

  String _compositeKey(String collection, String key) => '$collection::$key';

  IsarCollection<IsarKvEntry> get _kvCollection => _db.isarKvEntrys;

  Future<IsarKvEntry?> _findEntry(String collection, String key) async {
    final composite = _compositeKey(collection, key);
    return _kvCollection.filter().compositeKeyEqualTo(composite).findFirst();
  }

  Future<List<IsarKvEntry>> _findEntries(
      String collection, List<String> keys) async {
    final compositeKeys =
        keys.map((key) => _compositeKey(collection, key)).toList();
    return _kvCollection
        .filter()
        .anyOf(
            compositeKeys, (q, composite) => q.compositeKeyEqualTo(composite))
        .findAll();
  }

  Future<List<IsarKvEntry>> _entriesOf(String collection) =>
      _kvCollection.filter().collectionEqualTo(collection).findAll();

  T _decodeObject<T>(String value, DataModelAdapter<T> adapter) {
    final outerJson = jsonDecode(value) as String;
    final json = jsonDecode(outerJson) as JsonMap;
    return adapter.fromJson(json);
  }

  @override
  Future<void> put<T>(String collection, String key, T value) async {
    _ensureInitialized();
    await guardWrite('Failed to put key "$key" in "$collection"', () async {
      final composite = _compositeKey(collection, key);
      final entry = IsarKvEntry()
        ..compositeKey = composite
        ..collection = collection
        ..key = key
        ..value = jsonEncode(value);

      await _db.writeTxn(() async {
        final existing = await _kvCollection
            .filter()
            .compositeKeyEqualTo(composite)
            .findFirst();
        if (existing != null) {
          entry.id = existing.id;
        }
        await _kvCollection.put(entry);
      });
    });
  }

  @override
  Future<T?> get<T>(String collection, String key) async {
    _ensureInitialized();
    return guardRead('Failed to get key "$key" from "$collection"', () async {
      final entry = await _findEntry(collection, key);
      if (entry == null) return null;
      return jsonDecode(entry.value) as T;
    });
  }

  @override
  Future<void> delete(String collection, String key) async {
    _ensureInitialized();
    await guardWrite('Failed to delete key "$key" from "$collection"',
        () async {
      final entry = await _findEntry(collection, key);
      if (entry == null) return;
      await _db.writeTxn(() => _kvCollection.delete(entry.id));
    });
  }

  @override
  Future<void> deleteAll(String collection, List<String> keys) async {
    _ensureInitialized();
    if (keys.isEmpty) return;
    await guardWrite('Failed to delete keys $keys from "$collection"',
        () async {
      final entries = await _findEntries(collection, keys);
      if (entries.isEmpty) return;
      final ids = entries.map((e) => e.id).toList();
      await _db.writeTxn(() => _kvCollection.deleteAll(ids));
    });
  }

  @override
  Future<void> clear(String collection) async {
    _ensureInitialized();
    await guardWrite('Failed to clear "$collection"', () async {
      final entries = await _entriesOf(collection);
      final ids = entries.map((e) => e.id).toList();
      await _db.writeTxn(() => _kvCollection.deleteAll(ids));
    });
  }

  @override
  Future<List<T>> getAll<T>(String collection) async {
    _ensureInitialized();
    return guardRead('Failed to get all values from "$collection"', () async {
      final entries = await _entriesOf(collection);
      return entries.map((e) => jsonDecode(e.value) as T).toList();
    });
  }

  @override
  Future<List<String>> getAllKeys(String collection) async {
    _ensureInitialized();
    return guardRead('Failed to get all keys from "$collection"', () async {
      final entries = await _entriesOf(collection);
      return entries.map((e) => e.key).toList();
    });
  }

  @override
  Future<bool> containsKey(String collection, String key) async {
    _ensureInitialized();
    return guardRead('Failed to look up key "$key" in "$collection"',
        () async {
      final entry = await _findEntry(collection, key);
      return entry != null;
    });
  }

  @override
  Future<int> count(String collection) async {
    _ensureInitialized();
    return guardRead('Failed to count "$collection"',
        () => _kvCollection.filter().collectionEqualTo(collection).count());
  }

  @override
  Future<void> putObject<T>(
    String collection,
    String key,
    T value,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    await guardWrite('Failed to put object "$key" in "$collection"',
        () async {
      final jsonString = jsonEncode(adapter.toJson(value));
      await put<String>(collection, key, jsonString);
    });
  }

  @override
  Future<T?> getObject<T>(
    String collection,
    String key,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    return guardRead('Failed to get object "$key" from "$collection"',
        () async {
      final raw = await get<String>(collection, key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as JsonMap;
      return adapter.fromJson(json);
    });
  }

  @override
  Future<List<T>> getAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    return guardRead('Failed to get all objects from "$collection"',
        () async {
      final entries = await _entriesOf(collection);
      return entries.map((e) => _decodeObject(e.value, adapter)).toList();
    });
  }

  @override
  Future<void> putAll<T>(
    String collection,
    Map<String, T> entries,
  ) async {
    _ensureInitialized();
    await guardWrite('Failed to put ${entries.length} values in "$collection"',
        () async {
      await _db.writeTxn(() async {
        for (final entry in entries.entries) {
          final composite = _compositeKey(collection, entry.key);
          final existing = await _kvCollection
              .filter()
              .compositeKeyEqualTo(composite)
              .findFirst();

          final kvEntry = IsarKvEntry()
            ..compositeKey = composite
            ..collection = collection
            ..key = entry.key
            ..value = jsonEncode(entry.value);

          if (existing != null) {
            kvEntry.id = existing.id;
          }
          await _kvCollection.put(kvEntry);
        }
      });
    });
  }

  @override
  Future<void> putAllObjects<T>(
    String collection,
    Map<String, T> entries,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    await guardWrite(
        'Failed to put ${entries.length} objects in "$collection"', () async {
      final mapped = entries.map(
        (key, value) => MapEntry(key, jsonEncode(adapter.toJson(value))),
      );
      await putAll<String>(collection, mapped);
    });
  }

  @override
  Stream<T?> watch<T>(String collection, String key) {
    _ensureInitialized();
    return guardStream(
      'Failed to watch key "$key" in "$collection"',
      () => _kvCollection
          .filter()
          .compositeKeyEqualTo(_compositeKey(collection, key))
          .watch(fireImmediately: true)
          .map((entries) {
        if (entries.isEmpty) return null;
        return jsonDecode(entries.first.value) as T;
      }),
    );
  }

  @override
  Stream<T?> watchObject<T>(
    String collection,
    String key,
    DataModelAdapter<T> adapter,
  ) {
    _ensureInitialized();
    return guardStream(
      'Failed to watch object "$key" in "$collection"',
      () => _kvCollection
          .filter()
          .compositeKeyEqualTo(_compositeKey(collection, key))
          .watch(fireImmediately: true)
          .map((entries) {
        if (entries.isEmpty) return null;
        return _decodeObject(entries.first.value, adapter);
      }),
    );
  }

  @override
  Stream<List<T>> watchAll<T>(String collection) {
    _ensureInitialized();
    return guardStream(
      'Failed to watch "$collection"',
      () => _kvCollection
          .filter()
          .collectionEqualTo(collection)
          .watch(fireImmediately: true)
          .map((entries) =>
              entries.map((e) => jsonDecode(e.value) as T).toList()),
    );
  }

  @override
  Stream<List<T>> watchAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  ) {
    _ensureInitialized();
    return guardStream(
      'Failed to watch objects in "$collection"',
      () => _kvCollection
          .filter()
          .collectionEqualTo(collection)
          .watch(fireImmediately: true)
          .map((entries) =>
              entries.map((e) => _decodeObject(e.value, adapter)).toList()),
    );
  }

  @override
  core.QueryBuilder<T> query<T>(
    String collection,
    DataModelAdapter<T> adapter,
  ) {
    _ensureInitialized();
    return core.InMemoryQueryBuilder<T>(
      fetcher: () => getAllObjects<T>(collection, adapter),
      watcher: () => watchAllObjects<T>(collection, adapter),
    );
  }

  /// Runs [action] in an Isar write transaction. Whatever [action] throws
  /// reaches the caller unchanged.
  @override
  Future<void> transaction(Future<void> Function() action) async {
    _ensureInitialized();
    await _db.writeTxn(() => action());
  }

  @override
  NativeCollectionAccessor<T> native<T>(String collection) {
    _ensureInitialized();
    final cached = _nativeAccessors[collection];
    if (cached != null) return cached as NativeCollectionAccessor<T>;

    final IsarCollection<T> isarCollection;
    try {
      isarCollection = _db.collection<T>();
    } catch (e) {
      throw UnsupportedOperationException(
        'No Isar collection for $T. '
        'Pass its schema in IsarDataSourceConfig.schemas. ($e)',
      );
    }
    final accessor = IsarNativeAccessor<T>(_db, isarCollection);
    _nativeAccessors[collection] = accessor;
    return accessor;
  }

  @override
  Future<void> drop({String? collection}) async {
    _ensureInitialized();
    await guardWrite(
        collection != null
            ? 'Failed to drop "$collection"'
            : 'Failed to drop the database', () async {
      if (collection != null) {
        final entries = await _entriesOf(collection);
        if (entries.isEmpty) return;
        final ids = entries.map((e) => e.id).toList();
        await _db.writeTxn(() => _kvCollection.deleteAll(ids));
      } else {
        await _db.clear();
      }
    });
  }
}
