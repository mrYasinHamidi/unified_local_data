import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_ce/hive_ce.dart' as hive;

import '../../core/data_model.dart';
import '../../core/exceptions.dart';
import '../../core/unified_data_source.dart';
import '../../core/native_collection_accessor.dart';
import '../../core/query_builder.dart';
import '../../core/typedefs.dart';
import 'hive_config.dart';
import 'hive_native_accessor.dart';

final class HiveDataSource implements UnifiedDataSource {
  /// The box where the data source records the name of every collection it
  /// opens, so that [drop] can reach collections not opened in the current
  /// run. Don't use it as a collection name.
  static const registryBoxName = '_uld_collections';

  final HiveDataSourceConfig config;
  final Map<String, hive.Box<dynamic>> _boxCache = {};
  final Map<String, NativeCollectionAccessor<dynamic>> _nativeAccessors = {};
  hive.Box<dynamic>? _registry;
  bool _initialized = false;

  HiveDataSource({required this.config});

  @override
  Future<void> init() async {
    if (_initialized) return;
    hive.Hive.init(config.directory);
    _registry = await _openHiveBox<dynamic>(registryBoxName);

    for (final boxName in config.preloadBoxes) {
      await _openBox(boxName);
    }

    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    for (final box in _boxCache.values) {
      if (box.isOpen) await box.close();
    }
    final registry = _registry;
    if (registry != null && registry.isOpen) await registry.close();
    _registry = null;
    _boxCache.clear();
    _nativeAccessors.clear();
    _initialized = false;
  }

  Future<hive.Box<T>> _openHiveBox<T>(String name) {
    final encryption = config.encryption;
    return hive.Hive.openBox<T>(
      name,
      encryptionCipher:
          encryption != null ? hive.HiveAesCipher(encryption.key) : null,
    );
  }

  Future<hive.Box<dynamic>> _openBox(String name) async {
    final cached = _boxCache[name];
    if (cached != null && cached.isOpen) return cached;

    final box = await _openHiveBox<dynamic>(name);
    _boxCache[name] = box;
    await _record(name);
    return box;
  }

  Future<hive.Box<T>> openTypedBox<T>(String name) async {
    _ensureInitialized();
    final box = await _openHiveBox<T>(name);
    _boxCache[name] = box;
    await _record(name);
    return box;
  }

  /// Adds [name] to the registry. Hive lower-cases box names, so the
  /// registry does too.
  Future<void> _record(String name) async {
    final registry = _registry;
    final boxName = name.toLowerCase();
    if (registry == null ||
        boxName == registryBoxName ||
        registry.containsKey(boxName)) {
      return;
    }
    await registry.put(boxName, true);
  }

  void _ensureInitialized() {
    if (!_initialized) throw const DataSourceNotInitializedException();
  }

  @override
  Future<void> put<T>(String collection, String key, T value) async {
    _ensureInitialized();
    try {
      final box = await _openBox(collection);
      await box.put(key, value);
    } catch (e) {
      throw DataSourceWriteException(
          'Failed to put key=\$key in \$collection', e);
    }
  }

  @override
  Future<T?> get<T>(String collection, String key) async {
    _ensureInitialized();
    try {
      final box = await _openBox(collection);
      final value = box.get(key);
      if (value == null) return null;
      return value as T;
    } catch (e) {
      throw DataSourceReadException(
          'Failed to get key=\$key from \$collection', e);
    }
  }

  @override
  Future<void> delete(String collection, String key) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    await box.delete(key);
  }

  @override
  Future<void> deleteAll(String collection, List<String> keys) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    await box.deleteAll(keys);
  }

  @override
  Future<void> clear(String collection) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    await box.clear();
  }

  @override
  Future<List<T>> getAll<T>(String collection) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    return box.values.cast<T>().toList();
  }

  @override
  Future<List<String>> getAllKeys(String collection) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    return box.keys.cast<String>().toList();
  }

  @override
  Future<bool> containsKey(String collection, String key) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    return box.containsKey(key);
  }

  @override
  Future<int> count(String collection) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    return box.length;
  }

  @override
  Future<void> putObject<T>(
    String collection,
    String key,
    T value,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    try {
      final box = await _openBox(collection);
      final jsonString = jsonEncode(adapter.toJson(value));
      await box.put(key, jsonString);
    } catch (e) {
      throw DataSourceWriteException(
          'Failed to putObject key=\$key in \$collection', e);
    }
  }

  @override
  Future<T?> getObject<T>(
    String collection,
    String key,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    try {
      final box = await _openBox(collection);
      final raw = box.get(key);
      if (raw == null) return null;
      final json = jsonDecode(raw as String) as JsonMap;
      return adapter.fromJson(json);
    } catch (e) {
      throw DataSourceReadException(
          'Failed to getObject key=\$key from \$collection', e);
    }
  }

  @override
  Future<List<T>> getAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    return box.values.map((raw) {
      final json = jsonDecode(raw as String) as JsonMap;
      return adapter.fromJson(json);
    }).toList();
  }

  @override
  Future<void> putAll<T>(
    String collection,
    Map<String, T> entries,
  ) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    await box.putAll(entries);
  }

  @override
  Future<void> putAllObjects<T>(
    String collection,
    Map<String, T> entries,
    DataModelAdapter<T> adapter,
  ) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    final serialized = entries.map(
      (key, value) => MapEntry(key, jsonEncode(adapter.toJson(value))),
    );
    await box.putAll(serialized);
  }

  @override
  Stream<T?> watch<T>(String collection, String key) async* {
    _ensureInitialized();
    final box = await _openBox(collection);
    yield box.get(key) as T?;
    yield* box.watch(key: key).map((event) => event.value as T?);
  }

  @override
  Stream<T?> watchObject<T>(
    String collection,
    String key,
    DataModelAdapter<T> adapter,
  ) async* {
    _ensureInitialized();
    final box = await _openBox(collection);

    T? decode(dynamic raw) {
      if (raw == null) return null;

      final json = jsonDecode(raw as String) as JsonMap;
      return adapter.fromJson(json);
    }

    yield decode(box.get(key));
    yield* box.watch(key: key).map((raw) => decode(raw.value));
  }

  @override
  Stream<List<T>> watchAll<T>(String collection) async* {
    _ensureInitialized();
    final box = await _openBox(collection);
    yield box.values.cast<T>().toList();
    yield* box.watch().map((_) => box.values.cast<T>().toList());
  }

  @override
  Stream<List<T>> watchAllObjects<T>(
    String collection,
    DataModelAdapter<T> adapter,
  ) async* {
    _ensureInitialized();
    final box = await _openBox(collection);
    List<T> decode() => box.values.map((raw) {
          final json = jsonDecode(raw as String) as JsonMap;
          return adapter.fromJson(json);
        }).toList();
    yield decode();
    yield* box.watch().map((_) => decode());
  }

  @override
  QueryBuilder<T> query<T>(
    String collection,
    DataModelAdapter<T> adapter,
  ) {
    _ensureInitialized();
    return InMemoryQueryBuilder<T>(
      fetcher: () => getAllObjects<T>(collection, adapter),
      watcher: () => watchAllObjects<T>(collection, adapter),
    );
  }

  @override
  Future<void> transaction(Future<void> Function() action) async {
    _ensureInitialized();
    await action();
  }

  @override
  NativeCollectionAccessor<T> native<T>(String collection) {
    _ensureInitialized();
    final cached = _nativeAccessors[collection];
    if (cached != null) return cached as NativeCollectionAccessor<T>;

    final box = _boxCache[collection];
    if (box == null || box is! hive.Box<T>) {
      throw const UnsupportedOperationException(
        'No typed Box<\$T> found for "\$collection". '
        'Open the box with openTypedBox<\$T>() first.',
      );
    }

    final accessor = HiveNativeAccessor<T>(box);
    _nativeAccessors[collection] = accessor;
    return accessor;
  }

  @override
  Future<void> drop({String? collection}) async {
    _ensureInitialized();
    final registry = _registry!;
    final names = collection != null
        ? {collection.toLowerCase()}
        : {
            ...registry.keys.cast<String>(),
            ..._boxCache.keys,
            ...config.collections,
            ...config.preloadBoxes,
          }.map((name) => name.toLowerCase()).toSet();
    names.remove(registryBoxName);

    for (final name in names) {
      if (kIsWeb) {
        // Each box is its own IndexedDB database, and deleting one waits
        // until every other connection to it closes, which a connection from
        // another tab may never do. A clear is an ordinary write, and open
        // watch streams see it.
        final box = await _openHiveBox<dynamic>(name);
        await box.clear();
      } else {
        // Deletes an open box through the box, and an unopened one through
        // its files.
        await hive.Hive.deleteBoxFromDisk(name);
      }
    }

    _boxCache.removeWhere((name, _) => names.contains(name.toLowerCase()));
    _nativeAccessors
        .removeWhere((name, _) => names.contains(name.toLowerCase()));
    if (collection != null) {
      await registry.delete(collection.toLowerCase());
    } else {
      await registry.clear();
    }
  }
}
