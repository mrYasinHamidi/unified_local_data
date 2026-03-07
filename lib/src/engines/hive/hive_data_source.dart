import 'dart:async';
import 'dart:convert';

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
  final HiveDataSourceConfig config;
  final Map<String, hive.Box<dynamic>> _boxCache = {};
  final Map<String, NativeCollectionAccessor<dynamic>> _nativeAccessors = {};
  bool _initialized = false;

  HiveDataSource({required this.config});

  @override
  Future<void> init() async {
    if (_initialized) return;
    hive.Hive.init(config.directory);

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
    _boxCache.clear();
    _nativeAccessors.clear();
    _initialized = false;
  }

  Future<hive.Box<dynamic>> _openBox(String name) async {
    final cached = _boxCache[name];
    if (cached != null && cached.isOpen) return cached;

    final hive.Box<dynamic> box;
    final encryption = config.encryption;
    if (encryption != null) {
      box = await hive.Hive.openBox(
        name,
        encryptionCipher: hive.HiveAesCipher(encryption.key),
      );
    } else {
      box = await hive.Hive.openBox(name);
    }

    _boxCache[name] = box;
    return box;
  }

  Future<hive.Box<T>> openTypedBox<T>(String name) async {
    _ensureInitialized();
    final encryption = config.encryption;
    final hive.Box<T> box;
    if (encryption != null) {
      box = await hive.Hive.openBox<T>(
        name,
        encryptionCipher: hive.HiveAesCipher(encryption.key),
      );
    } else {
      box = await hive.Hive.openBox<T>(name);
    }
    _boxCache[name] = box;
    return box;
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
      throw DataSourceWriteException('Failed to put key=\$key in \$collection', e);
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
      throw DataSourceReadException('Failed to get key=\$key from \$collection', e);
    }
  }

  @override
  Future<void> delete(String collection, String key) async {
    _ensureInitialized();
    final box = await _openBox(collection);
    await box.delete(key);
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
      throw DataSourceWriteException('Failed to putObject key=\$key in \$collection', e);
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
      throw DataSourceReadException('Failed to getObject key=\$key from \$collection', e);
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
      throw UnsupportedOperationException(
        'No typed Box<\$T> found for "\$collection". '
        'Open the box with openTypedBox<\$T>() first.',
      );
    }

    final accessor = HiveNativeAccessor<T>(box);
    _nativeAccessors[collection] = accessor;
    return accessor;
  }
}
