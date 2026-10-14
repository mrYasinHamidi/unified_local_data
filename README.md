
<p align="center">
  <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform" />
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.4-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <a href="https://pub.dev/packages/unified_local_data"><img src="https://img.shields.io/pub/v/unified_local_data" alt="pub.dev version" /></a>
</p>

<h1 align="center">📦 unified_local_data</h1>

<p align="center">
  <strong>A universal, engine-agnostic local database abstraction layer for Flutter.</strong>
  <br />
  Swap between Hive, Isar, or any future engine — without changing a single line of your app logic.
</p>

---

## Table of Contents

- [Overview](#overview)
- [Why unified\_local\_data?](#why-unified_local_data)
- [Architecture](#architecture)
- [Supported Engines](#supported-engines)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [Initialize with Hive](#initialize-with-hive)
  - [Initialize with Isar](#initialize-with-isar)
- [Core API Reference](#core-api-reference)
  - [Primitives (put / get / delete)](#primitives)
  - [Complex Objects (Generic Path)](#complex-objects-generic-path)
  - [Batch Operations](#batch-operations)
  - [Collection Utilities](#collection-utilities)
  - [Reactive Streams](#reactive-streams)
  - [Query Builder](#query-builder)
  - [Transactions](#transactions)
- [Native Engine Access](#native-engine-access)
  - [Understanding the Two Paths](#understanding-the-two-paths)
  - [NativeCollectionAccessor API](#nativecollectionaccessor-api)
  - [Hive — Native TypeAdapter Flow](#hive--native-typeadapter-flow)
  - [Isar — Native @collection Flow](#isar--native-collection-flow)
  - [Isar — Raw Instance Access](#isar--raw-instance-access)
  - [When to Use Which Path](#when-to-use-which-path)
- [Swapping Engines](#swapping-engines)
- [Extending with a New Engine](#extending-with-a-new-engine)
- [Error Handling](#error-handling)
- [Stream Extensions](#stream-extensions)
- [Design Patterns](#design-patterns)
- [Folder Structure](#folder-structure)
- [FAQ](#faq)
- [License](#license)

---

## Overview

`unified_local_data` is a **production-grade Dart package** that provides a single, unified interface for all local database operations in Flutter apps. It decouples your application logic from any specific database engine using the **Strategy Pattern**, enabling you to switch between [Hive CE](https://pub.dev/packages/hive_ce) and [Isar Community](https://pub.dev/packages/isar_community) — or plug in any future engine — with zero refactoring.

The package offers **two data access paths**:

- **Generic Path** — Engine-agnostic `put`/`get`/`putObject` API using JSON serialization. Fully portable across all engines.
- **Native Path** — Direct access to engine-native features like Hive `TypeAdapter` and Isar `@collection` with full index, binary speed, and native query support.

---

## Why unified_local_data?

| Pain Point | Solution |
|---|---|
| Locked into one database across all projects | Engine-agnostic interface — pick per project |
| Migrating databases requires rewriting data layer | Swap via a single config change |
| Inconsistent API between Hive and Isar | One unified API for all engines |
| No reactive support out of the box | Built-in `Stream` watching for keys and collections |
| Complex objects need boilerplate per engine | Generic `DataModelAdapter<T>` handles serialization universally |
| Querying differs wildly between engines | Unified `QueryBuilder<T>` with filter, sort, limit, offset |
| Adding a new engine means rewriting everything | Implement `UnifiedDataSource` for it; code written against the interface doesn't change |
| Can't use Hive TypeAdapters or Isar @collection natively | `NativeCollectionAccessor<T>` gives full engine-native power |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                       │
├──────────────────────────────┬───────────────────────────────┤
│  Generic Path (portable)     │  Native Path (per engine)     │
│                              │                               │
│  UnifiedDataSource           │  NativeCollectionAccessor<T>  │
│  put / get / putObject       │  Hive: TypeAdapter            │
│  stored as JSON              │  Isar: @collection            │
└──────────────┬───────────────┴───────────────┬───────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────────────────────────────────────────────┐
│              UnifiedDataSourceFactory.create()               │
│            (singleton · picks the engine · init)             │
└──────────────┬───────────────────────────────┬───────────────┘
               │                               │
               ▼                               ▼
┌─────────────────────────────┐ ┌──────────────────────────────┐
│  HiveDataSource             │ │  IsarDataSource              │
│  implements                 │ │  implements                  │
│  UnifiedDataSource          │ │  UnifiedDataSource           │
│                             │ │                              │
│  Generic: Box<dynamic>      │ │  Generic: IsarKvEntry        │
│  Native:  Box<T>            │ │  Native:  IsarCollection<T>  │
│           + TypeAdapter     │ │           + @collection      │
└─────────────────────────────┘ └──────────────────────────────┘
```

---

## Supported Engines

| Engine | Use Case | Package |
|---|---|---|
| **Hive CE** | Fast key-value storage, lightweight apps, caching | [hive_ce](https://pub.dev/packages/hive_ce) |
| **Isar Community** | Complex queries, relational data, large datasets | [isar_community](https://pub.dev/packages/isar_community) |
| **Your Engine** | Anything else, by implementing `UnifiedDataSource` | See [Extending](#extending-with-a-new-engine) |

---

## Installation

```bash
flutter pub add unified_local_data
```

Or add it to your `pubspec.yaml` yourself:

```yaml
dependencies:
  unified_local_data: ^1.2.1
```

The package depends on Hive CE and Isar Community itself, so the generic path needs nothing else. If you use the native path and import `hive_ce` or `isar_community` in your own code, add that package to your `pubspec.yaml` too, along with its generator for `build_runner`.

---

## Quick Start

### Initialize with Hive

```dart
import 'package:unified_local_data/unified_local_data.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await UnifiedDataSourceFactory.create(
    UnifiedDataSourceConfig.hive(
      directory: dir.path,
      preloadBoxes: ['settings', 'cache'],
    ),
  );

  await db.put<String>('settings', 'language', 'en');
  final language = await db.get<String>('settings', 'language');
}
```

| Option | Description |
|---|---|
| `directory` | Where Hive keeps its box files. Ignored on the web. |
| `preloadBoxes` | Collections opened during `init()`. |
| `collections` | Collections that `drop()` always covers, without opening them at `init()`. See below. |
| `encryption` | An AES key for every box. |

The Hive engine records the name of every collection it opens in a reserved box, `_uld_collections`, so that `drop()` can reach collections the app hasn't opened since it started. Don't use that name for a collection.

Versions before 1.2.0 kept no such record. If your app has shipped with an earlier version, pass its collection names as `collections`, so `drop()` also covers boxes written before the update:

```dart
UnifiedDataSourceConfig.hive(
  directory: dir.path,
  collections: ['auth', 'app_config', 'map_memory'],
);
```

### Initialize with Isar

```dart
import 'package:unified_local_data/unified_local_data.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await UnifiedDataSourceFactory.create(
    UnifiedDataSourceConfig.isar(
      directory: dir.path,
      schemas: [],
      maxSizeMiB: 512,
      inspector: true,
    ),
  );

  await db.put<int>('analytics', 'launch_count', 42);
  final count = await db.get<int>('analytics', 'launch_count');
}
```

> **That's it.** The rest of your code uses the same `UnifiedDataSource` API regardless of which engine is active.

---

## Core API Reference

All methods are available on the `UnifiedDataSource` interface returned by `UnifiedDataSourceFactory.create()`.

### Primitives

Store and retrieve simple Dart types: `String`, `int`, `double`, `bool`, and lists of them.

> **Lists and maps read back differently on each engine.** Isar round-trips values through JSON, so a list comes back as `List<dynamic>`. Hive keeps typed lists, but a map comes back as `Map<dynamic, dynamic>` once the app restarts. To read the same way on both:
>
> - Read lists as `List<dynamic>` and cast them: `(await db.get<List<dynamic>>('c', 'k'))?.cast<String>()`.
> - Store maps with `putObject` / `getObject` (see [Complex Objects](#complex-objects-generic-path)), not `put` / `get`. `get<Map<String, dynamic>>` throws a `DataSourceReadException` on Hive after a restart.

```dart
await db.put<String>('settings', 'theme', 'dark');

final theme = await db.get<String>('settings', 'theme');

await db.delete('settings', 'theme');

await db.deleteAll('settings', ['theme', 'locale']);

await db.clear('settings');

await db.drop(collection: 'settings');

await db.drop();
```

| Method | Signature | Description |
|---|---|---|
| `put<T>` | `Future<void> put<T>(String collection, String key, T value)` | Stores a value by key |
| `get<T>` | `Future<T?> get<T>(String collection, String key)` | Retrieves a value by key |
| `delete` | `Future<void> delete(String collection, String key)` | Removes a single key |
| `deleteAll` | `Future<void> deleteAll(String collection, List<String> keys)` | Removes several keys in one call |
| `clear` | `Future<void> clear(String collection)` | Removes all entries in a collection |
| `drop` | `Future<void> drop({String? collection})` | Deletes a collection from disk, or the whole database when `collection` is omitted |
| `dispose` | `Future<void> dispose()` | Closes the database and releases all resources |

> **`clear` vs `drop`:** `clear` empties a collection but keeps it available for reuse. `drop` removes the collection itself. Calling `drop()` with no argument wipes the entire database, including collections the app hasn't opened since it started.
>
> - **Hive, native:** `drop` deletes the box files.
> - **Hive, web:** `drop` empties each box but keeps its IndexedDB database. Deleting the database would wait until every other connection to it closed, and a connection held by another tab of the app never does. Another open tab still reads the old values from its in-memory copy until it reloads.
> - **Isar:** `drop` deletes every entry of the collection, or clears the whole database.

---

### Complex Objects (Generic Path)

Use `DataModelAdapter<T>` to serialize/deserialize any custom Dart object. This path stores objects as JSON strings, making it **fully portable** across all engines.

> **Tip:** If your model class already implements `toJson`/`fromJson`, you can optionally have it implement the `DataModel<T>` interface as a marker contract:
>
> ```dart
> abstract interface class DataModel<T> {
>   JsonMap toJson();
>   T fromJson(JsonMap json);
> }
> ```
>
> The adapter (`DataModelAdapter<T>`) is what the API actually uses; `DataModel<T>` is an optional structural contract you can adopt for consistency.

**Step 1 — Define your model:**

```dart
class User {
  final String id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
```

**Step 2 — Create an adapter:**

```dart
final userAdapter = DataModelAdapter<User>(
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
);
```

**Step 3 — Store and retrieve:**

```dart
final user = User(id: '1', name: 'Yasin', email: 'yasin@example.com');

await db.putObject<User>('users', 'user_1', user, userAdapter);

final retrieved = await db.getObject<User>('users', 'user_1', userAdapter);

final allUsers = await db.getAllObjects<User>('users', userAdapter);
```

| Method | Signature | Description |
|---|---|---|
| `putObject<T>` | `Future<void> putObject<T>(String collection, String key, T value, DataModelAdapter<T> adapter)` | Stores a complex object |
| `getObject<T>` | `Future<T?> getObject<T>(String collection, String key, DataModelAdapter<T> adapter)` | Retrieves a complex object |
| `getAllObjects<T>` | `Future<List<T>> getAllObjects<T>(String collection, DataModelAdapter<T> adapter)` | Retrieves all objects in a collection |

---

### Batch Operations

Write multiple entries in a single call for better performance.

```dart
await db.putAll<String>('settings', {
  'theme': 'dark',
  'language': 'en',
  'font_size': '16',
});

await db.putAllObjects<User>('users', {
  'user_1': User(id: '1', name: 'Yasin', email: 'yasin@example.com'),
  'user_2': User(id: '2', name: 'Ali', email: 'ali@example.com'),
}, userAdapter);
```

| Method | Signature | Description |
|---|---|---|
| `putAll<T>` | `Future<void> putAll<T>(String collection, Map<String, T> entries)` | Batch stores primitives |
| `putAllObjects<T>` | `Future<void> putAllObjects<T>(String collection, Map<String, T> entries, DataModelAdapter<T> adapter)` | Batch stores complex objects |

---

### Collection Utilities

```dart
final keys = await db.getAllKeys('users');

final exists = await db.containsKey('users', 'user_1');

final total = await db.count('users');

final allValues = await db.getAll<String>('settings');
```

| Method | Signature | Description |
|---|---|---|
| `getAll<T>` | `Future<List<T>> getAll<T>(String collection)` | All raw values in a collection |
| `getAllKeys` | `Future<List<String>> getAllKeys(String collection)` | All keys in a collection |
| `containsKey` | `Future<bool> containsKey(String collection, String key)` | Checks key existence |
| `count` | `Future<int> count(String collection)` | Entry count in a collection |

---

### Reactive Streams

Subscribe to real-time changes on keys, collections, or object collections.

```dart
db.watch<String>('settings', 'theme').listen((value) {
  print('Theme changed to: $value');
});

db.watchObject<User>('users', 'user_1', userAdapter).listen((user) {
  print('User changed: ${user?.name}');
});

db.watchAll<String>('settings').listen((values) {
  print('Settings updated: $values');
});

db.watchAllObjects<User>('users', userAdapter).listen((users) {
  print('Users updated: ${users.length}');
});
```

| Method | Signature | Description |
|---|---|---|
| `watch<T>` | `Stream<T?> watch<T>(String collection, String key)` | Watches a single key for changes |
| `watchObject<T>` | `Stream<T?> watchObject<T>(String collection, String key, DataModelAdapter<T> adapter)` | Watches a single key as a typed object; emits `null` when the key is absent |
| `watchAll<T>` | `Stream<List<T>> watchAll<T>(String collection)` | Watches entire collection |
| `watchAllObjects<T>` | `Stream<List<T>> watchAllObjects<T>(String collection, DataModelAdapter<T> adapter)` | Watches collection as typed objects |

> All streams emit the current value immediately upon subscription, then emit on every subsequent change.

---

### Query Builder

Build fluent, chainable queries with filtering, sorting, pagination, and reactive watching.

```dart
final activeUsers = await db
    .query<User>('users', userAdapter)
    .where((user) => user.name.startsWith('Y'))
    .sortBy((a, b) => a.name.compareTo(b.name))
    .limit(20)
    .offset(0)
    .findAll();

final firstMatch = await db
    .query<User>('users', userAdapter)
    .where((user) => user.email.contains('@example.com'))
    .findFirst();

final total = await db
    .query<User>('users', userAdapter)
    .where((user) => user.id.isNotEmpty)
    .count();

db.query<User>('users', userAdapter)
    .where((user) => user.name.contains('Yasin'))
    .sortBy((a, b) => a.name.compareTo(b.name))
    .limit(10)
    .watch()
    .listen((users) {
  print('Matching users: ${users.length}');
});
```

| Method | Signature | Description |
|---|---|---|
| `query<T>` | `QueryBuilder<T> query<T>(String collection, DataModelAdapter<T> adapter)` | Creates a query builder |
| `.where()` | `QueryBuilder<T> where(bool Function(T) clause)` | Adds a filter predicate |
| `.sortBy()` | `QueryBuilder<T> sortBy(int Function(T, T) comparator)` | Sets sort order |
| `.limit()` | `QueryBuilder<T> limit(int count)` | Limits result count |
| `.offset()` | `QueryBuilder<T> offset(int start)` | Skips first N results |
| `.findAll()` | `Future<List<T>> findAll()` | Executes and returns all matches |
| `.findFirst()` | `Future<T?> findFirst()` | Executes and returns first match |
| `.count()` | `Future<int> count()` | Returns number of matches |
| `.deleteAll()` | `Future<bool> deleteAll()` | Deletes all matched objects (native engines only; throws on generic in-memory path) |
| `.watch()` | `Stream<List<T>> watch()` | Watches query results reactively |

---

### Transactions

Wrap multiple operations in a transaction for atomicity.

```dart
await db.transaction(() async {
  await db.put<String>('settings', 'theme', 'dark');
  await db.put<String>('settings', 'language', 'en');
  await db.putObject<User>('users', 'user_1', newUser, userAdapter);
});
```

> **Hive**: Operations are executed sequentially (Hive has no native transaction support). If one fails, the writes before it stay.
>
> **Isar**: The action runs in one native `writeTxn`. Every data source call inside it, and every write through `native<T>()`, joins that transaction, and so does a nested `transaction()`. If the action throws, all of its writes are rolled back. Don't call `rawInstance.writeTxn()` inside it: Isar doesn't nest transactions.
>
> On both engines, `transaction` passes on whatever the action throws, unchanged.

---

## Native Engine Access

### Understanding the Two Paths

The package provides two distinct ways to store complex objects:

```
┌──────────────────────────────────────────────────────────────────────┐
│                        DECISION FLOWCHART                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Need to swap engines freely across projects?                        │
│  ├─ YES → Use Generic Path                                          │
│  │        db.putObject / db.getObject                                │
│  │        Uses DataModelAdapter<T> + JSON serialization              │
│  │        ✅ Works on ALL engines without changes                    │
│  │        ⚠️ No engine-native indexes or binary speed                │
│  │                                                                   │
│  └─ NO → Engine is fixed for this project?                           │
│     ├─ YES → Use Native Path                                         │
│     │        db.native<T>('collection')                              │
│     │        ✅ Full Hive TypeAdapter support                        │
│     │        ✅ Full Isar @collection + indexes                     │
│     │        ✅ Binary speed, zero JSON overhead                    │
│     │        ⚠️ Models are engine-specific                           │
│     │                                                                │
│     └─ Need Isar's full .filter().sortBy() generated DSL?           │
│        └─ Cast to IsarDataSource, use rawInstance                    │
│           ✅ Complete Isar native query power                       │
│           ❌ Completely tied to Isar                                │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

| Path | Portability | Performance | Query Power | Best For |
|---|---|---|---|---|
| **Generic** (`putObject`) | ✅ Any engine | Good | In-memory filter | Settings, cache, portable data |
| **Native** (`db.native<T>()`) | ⚠️ Engine-specific models | Best | In-memory filter | Domain entities with TypeAdapter / @collection |
| **Raw** (`rawInstance`) | ❌ Single engine only | Best | Full native DSL | Complex Isar queries with composite indexes |

---

### NativeCollectionAccessor API

The `NativeCollectionAccessor<T>` interface provides a unified API for working with engine-native models:

| Method | Signature | Description |
|---|---|---|
| `put` | `Future<void> put(T item)` | Stores a single native object |
| `putAll` | `Future<void> putAll(List<T> items)` | Batch stores native objects |
| `getById` | `Future<T?> getById(dynamic id)` | Retrieves by ID |
| `getAll` | `Future<List<T>> getAll()` | Retrieves all objects |
| `deleteById` | `Future<void> deleteById(dynamic id)` | Deletes by ID |
| `deleteAll` | `Future<void> deleteAll()` | Clears all objects |
| `count` | `Future<int> count()` | Returns object count |
| `watchAll` | `Stream<List<T>> watchAll()` | Watches all objects reactively |
| `watchById` | `Stream<T?> watchById(dynamic id)` | Watches a single object reactively |
| `query` | `QueryBuilder<T> query()` | Creates a chainable query builder |

---

### Hive — Native TypeAdapter Flow

Use Hive's native `TypeAdapter` for maximum binary serialization speed.

**Step 1 — Define your Hive model:**

```dart
import 'package:hive_ce/hive_ce.dart';

part 'user_entity.g.dart';

@HiveType(typeId: 1)
class UserEntity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
}
```

**Step 2 — Run code generation:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 3 — Register adapter, open typed box, and use:**

```dart
import 'package:hive_ce/hive_ce.dart';
import 'package:unified_local_data/unified_local_data.dart';
import 'package:path_provider/path_provider.dart';

import 'models/user_entity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  Hive.registerAdapter(UserEntityAdapter());

  final db = await UnifiedDataSourceFactory.create(
    UnifiedDataSourceConfig.hive(directory: dir.path),
  );

  final hiveDb = db as HiveDataSource;
  await hiveDb.openTypedBox<UserEntity>('users');

  final users = db.native<UserEntity>('users');

  await users.put(UserEntity(
    id: '1',
    name: 'Yasin',
    email: 'yasin@example.com',
    createdAt: DateTime.now(),
  ));

  await users.putAll([
    UserEntity(
      id: '2',
      name: 'Ali',
      email: 'ali@example.com',
      createdAt: DateTime.now(),
    ),
  ]);

  // NOTE: HiveNativeAccessor.putAll() uses box.addAll() — items are appended
  // with auto-incremented integer keys. For keyed upsert, call put() individually.

  final allUsers = await users.getAll();

  final yasin = await users.getById('1');

  users.watchAll().listen((userList) {
    print('Users changed: ${userList.length}');
  });

  final filtered = await users
      .query()
      .where((u) => u.name.startsWith('Y'))
      .sortBy((a, b) => a.createdAt.compareTo(b.createdAt))
      .limit(10)
      .findAll();
}
```

---

### Isar — Native @collection Flow

Use Isar's native `@collection` annotation for full index and schema support.

**Step 1 — Define your Isar model:**

```dart
import 'package:isar_community/isar.dart';

part 'product_entity.g.dart';

@collection
class ProductEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String title;

  late double price;

  @Index(composite: [CompositeIndex('price')])
  late String category;

  late DateTime createdAt;
}

@embedded
class Address {
  late String street;
  late String city;
  late String zipCode;
}
```

**Step 2 — Run code generation:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 3 — Pass schemas at init and use:**

```dart
import 'package:unified_local_data/unified_local_data.dart';
import 'package:path_provider/path_provider.dart';

import 'models/product_entity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await UnifiedDataSourceFactory.create(
    UnifiedDataSourceConfig.isar(
      directory: dir.path,
      schemas: [ProductEntitySchema],
    ),
  );

  final products = db.native<ProductEntity>('products');

  await products.put(
    ProductEntity()
      ..title = 'Flutter Widget'
      ..price = 29.99
      ..category = 'Development'
      ..createdAt = DateTime.now(),
  );

  await products.putAll([
    ProductEntity()
      ..title = 'Dart Package'
      ..price = 9.99
      ..category = 'Development'
      ..createdAt = DateTime.now(),
    ProductEntity()
      ..title = 'UI Kit'
      ..price = 49.99
      ..category = 'Design'
      ..createdAt = DateTime.now(),
  ]);

  final allProducts = await products.getAll();

  final product = await products.getById(1);

  products.watchAll().listen((productList) {
    print('Products changed: ${productList.length}');
  });

  final expensive = await products
      .query()
      .where((p) => p.price > 20.0)
      .sortBy((a, b) => b.price.compareTo(a.price))
      .limit(5)
      .findAll();
}
```

---

### Isar — Raw Instance Access

When you need Isar's **full native query DSL** — generated `.filter()`, `.sortBy()`, composite index queries — access the raw Isar instance directly:

```dart
import 'package:isar_community/isar.dart';
import 'package:unified_local_data/unified_local_data.dart';

import 'models/product_entity.dart';

Future<void> advancedIsarQuery(UnifiedDataSource db) async {
  final isarDb = db as IsarDataSource;
  final isar = isarDb.rawInstance;

  final results = await isar.productEntitys
      .filter()
      .categoryEqualTo('Development')
      .and()
      .priceGreaterThan(10.0)
      .sortByPriceDesc()
      .limit(20)
      .findAll();

  isar.productEntitys
      .filter()
      .priceGreaterThan(50)
      .watch(fireImmediately: true)
      .listen((premiumProducts) {
    print('Premium products: ${premiumProducts.length}');
  });
}
```

> ⚠️ **Warning:** Using `rawInstance` ties your code directly to Isar. This should be limited to repository implementations where you have consciously chosen Isar as the engine.

---

### When to Use Which Path

| Scenario | Recommended Path | Why |
|---|---|---|
| App settings, feature flags, simple cache | **Generic** `put`/`get` | Simple key-value, no need for native features |
| User profile, auth tokens | **Generic** `putObject` | Portable across engines, easy to serialize |
| Large product catalog with search | **Native** `db.native<T>()` | Benefits from Isar indexes and binary speed |
| Chat messages with complex queries | **Native** + **Raw** | Need Isar composite indexes and full-text search |
| Offline-first app with sync | **Native** `db.native<T>()` | Need full TypeAdapter/collection for performance |
| Shared package used across many projects | **Generic** path only | Maximum portability, no engine lock-in |
| Prototype / MVP | **Generic** path | Ship fast, optimize later |

---

## Swapping Engines

The entire point of this package — swap your database with **one config change**:

```dart
// Using Hive
final db = await UnifiedDataSourceFactory.create(
  UnifiedDataSourceConfig.hive(directory: dir.path),
);

// Switch to Isar — no other code changes needed (for Generic Path)
final db = await UnifiedDataSourceFactory.create(
  UnifiedDataSourceConfig.isar(directory: dir.path, schemas: []),
);
```

Swap at runtime:

```dart
// reset() calls dispose() on the current instance, then clears it
await UnifiedDataSourceFactory.reset();

await UnifiedDataSourceFactory.create(
  UnifiedDataSourceConfig.isar(directory: dir.path, schemas: []),
);

final db = UnifiedDataSourceFactory.instance;
```

You can also dispose a specific instance directly:

```dart
await db.dispose(); // closes the DB and frees all resources
```

> **Note:** `create()` automatically disposes any existing instance before creating the new one, so you don't need to call `reset()` first when simply switching configs.
>
> Code using the **Generic Path** (`put`/`get`/`putObject`) swaps seamlessly. Code using the **Native Path** (`db.native<T>()`) requires engine-specific models and may need adjustment when switching engines.

---

## Extending with a New Engine

`UnifiedDataSource` is an ordinary interface, so another engine (Drift, Sqflite, …) can sit behind it. There are two ways to add one.

### In your app

Implement `UnifiedDataSource` and create the data source yourself. `UnifiedDataSourceFactory` only builds the built-in engines, so it can't create this one; keep the instance wherever your app keeps its services.

```dart
final class DriftDataSource implements UnifiedDataSource {
  DriftDataSource({required this.databaseName});

  final String databaseName;

  @override
  Future<void> init() async { /* open the Drift database */ }

  @override
  Future<void> put<T>(String collection, String key, T value) async { /* ... */ }

  @override
  NativeCollectionAccessor<T> native<T>(String collection) { /* ... */ }

  // ... implement all other methods
}

final db = DriftDataSource(databaseName: 'app');
await db.init();
```

Code written against `UnifiedDataSource` works with it unchanged. To behave like the built-in engines, report failures as `DataSourceReadException` and `DataSourceWriteException` (see [Error Handling](#error-handling)).

### In this package

For `UnifiedDataSourceFactory.create()` to build the new engine, the package itself changes in three places:

1. Add a value to `DatabaseEngine` in `lib/src/core/unified_data_source_config.dart`, and a factory constructor on `UnifiedDataSourceConfig` if you want one.
2. Add the config class, which extends `UnifiedDataSourceConfig`, and the data source under `lib/src/engines/<engine>/`, and export both from `lib/unified_local_data.dart`.
3. Add a case to the `switch` in `UnifiedDataSourceFactory.create()`:

```dart
final UnifiedDataSource dataSource = switch (config) {
  HiveDataSourceConfig c => HiveDataSource(config: c),
  IsarDataSourceConfig c => IsarDataSource(config: c),
  DriftDataSourceConfig c => DriftDataSource(config: c),
  _ => throw UnsupportedError(
      'Unsupported config type: ${config.runtimeType}'),
};
```

---

## Error Handling

The package uses a sealed exception hierarchy for exhaustive, compile-time checked error handling:

```dart
try {
  final value = await db.get<String>('settings', 'theme');
} on DataSourceNotInitializedException {
  // Database not initialized — call init() first
} on DataSourceReadException catch (e) {
  print('Read error: ${e.message}, cause: ${e.cause}');
} on DataSourceWriteException catch (e) {
  print('Write error: ${e.message}, cause: ${e.cause}');
} on DataNotFoundException catch (e) {
  // Requested data does not exist
} on UnsupportedOperationException catch (e) {
  // Operation not supported by current engine
} on LocalDataSourceException catch (e) {
  // Catch-all for any data source error
}
```

| Exception | When |
|---|---|
| `DataSourceNotInitializedException` | `init()` was not called before usage |
| `DataSourceReadException` | A read operation fails (corruption, cast error, etc.) |
| `DataSourceWriteException` | A write operation fails (disk full, permission, etc.) |
| `DataNotFoundException` | Explicitly requested data does not exist |
| `UnsupportedOperationException` | Operation not available on current engine |

Every operation on the data source reports its failures this way, on both engines:

- Reads throw `DataSourceReadException`; writes, deletes, `clear` and `drop` throw `DataSourceWriteException`. The engine's own error is in `cause`, and the original stack trace is kept.
- The message names the key and the collection, for example `Failed to get key "camera" from "map_memory"`.
- Watch streams (`watch`, `watchObject`, `watchAll`, `watchAllObjects`) emit their errors as `DataSourceReadException` instead of throwing them.
- `transaction` passes on whatever its action throws, unchanged.
- The native path (`NativeCollectionAccessor`, `openTypedBox`'s box, Isar's `rawInstance`) is the engine itself and throws the engine's errors.

---

## Stream Extensions

The package includes utility extensions for working with reactive streams:

```dart
import 'package:unified_local_data/unified_local_data.dart';

db.watchAll<String>('settings')
    .debounceTime(Duration(milliseconds: 300))
    .listen((values) {
  print('Debounced update: $values');
});

db.watch<String>('settings', 'theme')
    .distinctUntilChanged()
    .listen((value) {
  print('Theme actually changed to: $value');
});
```

| Extension | Description |
|---|---|
| `.debounceTime(Duration)` | Waits for a pause in emissions before forwarding |
| `.distinctUntilChanged()` | Filters out consecutive duplicate values |

---

## Design Patterns

| Pattern | Where | Purpose |
|---|---|---|
| **Strategy** | `UnifiedDataSource` interface + engine implementations | Swap database engine without changing consumer code |
| **Factory** | `UnifiedDataSourceFactory` | Unified creation by matching on the config type |
| **Adapter** | `DataModelAdapter<T>` + `NativeCollectionAccessor<T>` | Bridge between domain models and storage |
| **Repository** | Each engine implementation | Encapsulates all data access behind a single contract |
| **Singleton** | `UnifiedDataSourceFactory._instance` | Single database instance across the app |
| **Builder** | `QueryBuilder<T>` chain | Fluent query construction with deferred execution |
| **Sealed Class** | Exceptions hierarchy | Exhaustive compile-time checked exception types |
| **Abstract Class** | `UnifiedDataSourceConfig` | Shared config base with engine-specific subclasses |

---

## Folder Structure

```
unified_local_data/
├── pubspec.yaml
├── example/
│   └── lib/main.dart                              # Minimal Hive example
├── lib/
│   ├── unified_local_data.dart                    # Public barrel export
│   └── src/
│       ├── core/
│       │   ├── unified_data_source.dart           # The UnifiedDataSource interface
│       │   ├── unified_data_source_config.dart    # Base config and DatabaseEngine
│       │   ├── unified_data_source_factory.dart   # UnifiedDataSourceFactory
│       │   ├── data_model.dart                    # DataModel<T> + DataModelAdapter<T>
│       │   ├── native_collection_accessor.dart    # Native engine access interface
│       │   ├── query_builder.dart                 # QueryBuilder<T> + in-memory builder
│       │   ├── exceptions.dart                    # Sealed exception hierarchy
│       │   ├── guard.dart                         # Wraps engine errors in those exceptions
│       │   └── typedefs.dart                      # Shared type aliases
│       ├── engines/
│       │   ├── hive/
│       │   │   ├── hive_data_source.dart          # Hive implementation
│       │   │   ├── hive_native_accessor.dart      # Hive TypeAdapter accessor
│       │   │   └── hive_config.dart               # Hive-specific configuration
│       │   └── isar/
│       │       ├── isar_data_source.dart          # Isar implementation
│       │       ├── isar_native_accessor.dart      # Isar @collection accessor
│       │       ├── isar_config.dart               # Isar-specific configuration
│       │       ├── isar_txn.dart                  # Write transactions that join transaction()
│       │       ├── isar_kv_entry.dart             # Internal @collection for the generic path
│       │       └── isar_kv_entry.g.dart           # Generated Isar schema (build_runner)
│       └── extensions/
│           └── stream_extensions.dart             # debounceTime, distinctUntilChanged
└── test/
    ├── hive_data_source_test.dart                 # Hive on the VM
    ├── hive_web_drop_test.dart                    # Hive in the browser
    ├── isar_data_source_test.dart                 # Isar on the VM
    ├── exceptions_test.dart
    ├── unified_data_source_test.dart
    └── support/operations.dart                    # Shared failure tests
```

---

## FAQ

<details>
<summary><strong>Can I use this in a pure Dart project (no Flutter)?</strong></summary>

No. The package depends on the Flutter SDK and on `isar_community_flutter_libs`, a Flutter plugin, so it needs a Flutter project. Its tests do run on the Dart VM through `flutter test`, with a temporary directory in place of `path_provider`.
</details>

<details>
<summary><strong>Do I need to register Hive TypeAdapters manually?</strong></summary>

**Generic Path:** No. Objects are serialized to JSON via `DataModelAdapter<T>`, avoiding the need for Hive TypeAdapter registration.

**Native Path:** Yes. Register your TypeAdapters before opening typed boxes:

```dart
Hive.registerAdapter(UserEntityAdapter());
final hiveDb = db as HiveDataSource;
await hiveDb.openTypedBox<UserEntity>('users');
```
</details>

<details>
<summary><strong>Do I need to define Isar @collection schemas?</strong></summary>

**Generic Path:** No. The package uses an internal `IsarKvEntry` collection for key-value storage.

**Native Path:** Yes. Define your `@collection` classes, run `build_runner`, and pass schemas at initialization:

```dart
UnifiedDataSourceConfig.isar(
  directory: dir.path,
  schemas: [ProductEntitySchema, OrderEntitySchema],
)
```
</details>

<details>
<summary><strong>Can I mix Generic and Native paths in the same project?</strong></summary>

Absolutely. This is a common and recommended pattern:

```dart
// Generic: app settings (portable)
await db.put<String>('settings', 'theme', 'dark');

// Native: domain entities (engine-optimized)
final products = db.native<ProductEntity>('products');
await products.put(myProduct);
```
</details>

<details>
<summary><strong>Can I access the raw Hive/Isar instance?</strong></summary>

Yes. Both engine implementations expose their raw instance for advanced use cases:

```dart
// Isar
final isarDb = db as IsarDataSource;
final isar = isarDb.rawInstance;

// Hive — access typed boxes directly
final hiveDb = db as HiveDataSource;
final box = await hiveDb.openTypedBox<UserEntity>('users');
```

This is intentionally not part of the `UnifiedDataSource` interface to maintain abstraction.
</details>

<details>
<summary><strong>Is this thread-safe?</strong></summary>

Yes. Both Hive and Isar handle concurrent access internally. The package uses `async/await` throughout and avoids shared mutable state beyond the singleton instance.
</details>

<details>
<summary><strong>What happens if I call methods before init()?</strong></summary>

A `DataSourceNotInitializedException` is thrown immediately. Always call `UnifiedDataSourceFactory.create()` before accessing the database.
</details>

<details>
<summary><strong>How do I encrypt my data?</strong></summary>

With Hive, pass an encryption config:

```dart
UnifiedDataSourceConfig.hive(
  directory: dir.path,
  encryption: HiveEncryptionConfig(key: mySecureKey),
);
```

Isar Community does not support encryption natively. You can encrypt at the application layer using the `DataModelAdapter<T>` serialization step.
</details>

<details>
<summary><strong>When should I call dispose()?</strong></summary>

Call `dispose()` when your app is shutting down or when you want to explicitly release database resources. Both engine implementations close all open boxes/databases and clear internal caches.

```dart
// Dispose directly on the instance
await db.dispose();

// Or via the factory (also clears the singleton)
await UnifiedDataSourceFactory.reset();
```

`UnifiedDataSourceFactory.create()` automatically calls `dispose()` on any existing instance before opening the new one, so manual disposal is only needed on app exit or in tests.
</details>

<details>
<summary><strong>How do I handle schema migrations?</strong></summary>

**Generic Path:** Since objects are stored as JSON, schema evolution is handled by your model's `fromJson` factory. Add default values for new fields and handle missing keys gracefully.

**Native Path (Hive):** Hive TypeAdapters handle field additions via `@HiveField` indices. New fields with higher indices are backward-compatible.

**Native Path (Isar):** Isar handles schema migrations automatically for non-breaking changes (adding fields, indexes). For breaking changes, consult the [Isar migration guide](https://isar-community.dev/v3/).
</details>

<details>
<summary><strong>What if my engine doesn't support a specific operation?</strong></summary>

The engine implementation should throw `UnsupportedOperationException` for operations it cannot fulfill. The sealed exception hierarchy allows you to handle this gracefully:

```dart
try {
  await db.transaction(() async { /* ... */ });
} on UnsupportedOperationException {
  // Fallback: execute operations without transaction
}
```
</details>

---

## License

```
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<p align="center">
  Built with ❤️ for the Flutter community
  <br />
  <strong>One interface. Any engine. Zero rewrites.</strong>
  <br />
  <sub>Generic when you need portability. Native when you need power.</sub>
</p>
