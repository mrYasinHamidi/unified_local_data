
<p align="center">
  <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform" />
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.0-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/Version-1.0.0-blue" alt="Version" />
</p>

<h1 align="center">📦 local_data_source</h1>

<p align="center">
  <strong>A universal, engine-agnostic local database abstraction layer for Flutter.</strong>
  <br />
  Swap between Hive, Isar, or any future engine — without changing a single line of your app logic.
</p>

---

## Table of Contents

- [Overview](#overview)
- [Why local\_data\_source?](#why-local_data_source)
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

`local_data_source` is a **production-grade Dart package** that provides a single, unified interface for all local database operations in Flutter apps. It decouples your application logic from any specific database engine using the **Strategy Pattern**, enabling you to switch between [Hive CE](https://pub.dev/packages/hive_ce) and [Isar Community](https://pub.dev/packages/isar_community) — or plug in any future engine — with zero refactoring.

The package offers **two data access paths**:

- **Generic Path** — Engine-agnostic `put`/`get`/`putObject` API using JSON serialization. Fully portable across all engines.
- **Native Path** — Direct access to engine-native features like Hive `TypeAdapter` and Isar `@collection` with full index, binary speed, and native query support.

---

## Why local_data_source?

| Pain Point | Solution |
|---|---|
| Locked into one database across all projects | Engine-agnostic interface — pick per project |
| Migrating databases requires rewriting data layer | Swap via a single config change |
| Inconsistent API between Hive and Isar | One unified API for all engines |
| No reactive support out of the box | Built-in `Stream` watching for keys and collections |
| Complex objects need boilerplate per engine | Generic `DataModelAdapter<T>` handles serialization universally |
| Querying differs wildly between engines | Unified `QueryBuilder<T>` with filter, sort, limit, offset |
| Adding a new engine means rewriting everything | Open/Closed Principle — add engines without touching core |
| Can't use Hive TypeAdapters or Isar @collection natively | `NativeCollectionAccessor<T>` gives full engine-native power |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     APPLICATION LAYER                        │
├─────────────────────────┬────────────────────────────────────┤
│   Generic Path          │   Native Path                     │
│   (Portable)            │   (Full Engine Power)             │
│                         │                                    │
│   LocalDataSource       │   NativeCollectionAccessor<T>     │
│   put/get/putObject     │   Hive: full TypeAdapter          │
│   via JSON              │   Isar: full @collection          │
└────────────┬────────────┴──────────────┬─────────────────────┘
             │                           │
             ▼                           ▼
┌──────────────────────────────────────────────────────────────┐
│              LocalDataSourceFactory.create()                  │
│          (Singleton · Strategy Selection · Init)             │
└────────────┬──────────────────────────────┬──────────────────┘
             │                              │
             ▼                              ▼
┌────────────────────────────┐  ┌───────────────────────────────┐
│     HiveDataSource         │  │     IsarDataSource            │
│     implements             │  │     implements                │
│     LocalDataSource        │  │     LocalDataSource           │
│                            │  │                               │
│  ┌──────────────────────┐  │  │  ┌─────────────────────────┐  │
│  │ Generic: Box<dynamic>│  │  │  │ Generic: IsarKvEntry    │  │
│  │ Native: Box<T>       │  │  │  │ Native: IsarCollection  │  │
│  │ + TypeAdapter        │  │  │  │ + @collection           │  │
│  └──────────────────────┘  │  │  └─────────────────────────┘  │
└────────────────────────────┘  └──────────────────────��────────┘
             │                              │
             ▼                              ▼
┌──────────────────────────────────────────────────────────────┐
│                    FUTURE ENGINE SLOT                         │
│         DriftDataSource / SqfliteDataSource / etc.           │
│         implements LocalDataSource                           │
└──────────────────────────────────────────────────────────────┘
```

---

## Supported Engines

| Engine | Use Case | Package |
|---|---|---|
| **Hive CE** | Fast key-value storage, lightweight apps, caching | [hive_ce](https://pub.dev/packages/hive_ce) |
| **Isar Community** | Complex queries, relational data, large datasets | [isar_community](https://pub.dev/packages/isar_community) |
| **Your Engine** | Extend anytime — zero changes to core | See [Extending](#extending-with-a-new-engine) |

---

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  local_data_source:
    path: packages/local_data_source  # or your git/pub reference
```

The package bundles both Hive CE and Isar Community internally. You do **not** need to add them separately.

---

## Quick Start

### Initialize with Hive

```dart
import 'package:local_data_source/local_data_source.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await LocalDataSourceFactory.create(
    LocalDataSourceConfig.hive(
      directory: dir.path,
      preloadBoxes: ['settings', 'cache'],
    ),
  );

  await db.put<String>('settings', 'language', 'en');
  final language = await db.get<String>('settings', 'language');
}
```

### Initialize with Isar

```dart
import 'package:local_data_source/local_data_source.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await LocalDataSourceFactory.create(
    LocalDataSourceConfig.isar(
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

> **That's it.** The rest of your code uses the same `LocalDataSource` API regardless of which engine is active.

---

## Core API Reference

All methods are available on the `LocalDataSource` interface returned by `LocalDataSourceFactory.create()`.

### Primitives

Store and retrieve simple Dart types (`String`, `int`, `double`, `bool`, `List`, `Map`).

```dart
await db.put<String>('settings', 'theme', 'dark');

final theme = await db.get<String>('settings', 'theme');

await db.delete('settings', 'theme');

await db.clear('settings');
```

| Method | Signature | Description |
|---|---|---|
| `put<T>` | `Future<void> put<T>(String collection, String key, T value)` | Stores a value by key |
| `get<T>` | `Future<T?> get<T>(String collection, String key)` | Retrieves a value by key |
| `delete` | `Future<void> delete(String collection, String key)` | Removes a single key |
| `clear` | `Future<void> clear(String collection)` | Removes all entries in a collection |

---

### Complex Objects (Generic Path)

Use `DataModelAdapter<T>` to serialize/deserialize any custom Dart object. This path stores objects as JSON strings, making it **fully portable** across all engines.

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

> **Hive**: Operations are executed sequentially (Hive has no native transaction support).
>
> **Isar**: Operations are wrapped in a native `writeTxn` for true ACID compliance.

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
import 'package:local_data_source/local_data_source.dart';
import 'package:path_provider/path_provider.dart';

import 'models/user_entity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  Hive.registerAdapter(UserEntityAdapter());

  final db = await LocalDataSourceFactory.create(
    LocalDataSourceConfig.hive(directory: dir.path),
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
import 'package:isar_community/isar_community.dart';

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
import 'package:local_data_source/local_data_source.dart';
import 'package:path_provider/path_provider.dart';

import 'models/product_entity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await LocalDataSourceFactory.create(
    LocalDataSourceConfig.isar(
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
import 'package:isar_community/isar_community.dart';
import 'package:local_data_source/local_data_source.dart';

import 'models/product_entity.dart';

Future<void> advancedIsarQuery(LocalDataSource db) async {
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
final db = await LocalDataSourceFactory.create(
  LocalDataSourceConfig.hive(directory: dir.path),
);

// Switch to Isar — no other code changes needed (for Generic Path)
final db = await LocalDataSourceFactory.create(
  LocalDataSourceConfig.isar(directory: dir.path, schemas: []),
);
```

Swap at runtime:

```dart
await LocalDataSourceFactory.reset();

await LocalDataSourceFactory.create(
  LocalDataSourceConfig.isar(directory: dir.path, schemas: []),
);

final db = LocalDataSourceFactory.instance;
```

> **Note:** Code using the **Generic Path** (`put`/`get`/`putObject`) swaps seamlessly. Code using the **Native Path** (`db.native<T>()`) requires engine-specific models and may need adjustment when switching engines.

---

## Extending with a New Engine

Adding a new database engine (e.g., Drift, Sqflite) requires **zero changes** to the core abstraction. This is the Open/Closed Principle in action.

**Step 1 — Add the engine enum value:**

```dart
enum DatabaseEngine { hive, isar, drift }
```

**Step 2 — Create engine-specific config:**

```dart
final class DriftDataSourceConfig extends LocalDataSourceConfig {
  final String databaseName;

  const DriftDataSourceConfig({
    required super.directory,
    required this.databaseName,
  }) : super(engine: DatabaseEngine.drift);
}
```

**Step 3 — Implement the interface:**

```dart
final class DriftDataSource implements LocalDataSource {
  final DriftDataSourceConfig config;

  DriftDataSource({required this.config});

  @override
  Future<void> init() async { /* Drift initialization */ }

  @override
  Future<void> put<T>(String collection, String key, T value) async { /* ... */ }

  @override
  NativeCollectionAccessor<T> native<T>(String collection) { /* ... */ }

  // ... implement all other methods
}
```

**Step 4 — Register in the factory (one line):**

```dart
final LocalDataSource dataSource = switch (config) {
  HiveDataSourceConfig() => HiveDataSource(config: config),
  IsarDataSourceConfig() => IsarDataSource(config: config),
  DriftDataSourceConfig() => DriftDataSource(config: config),
};
```

**That's it.** No existing code changes. Pure Open/Closed Principle.

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

---

## Stream Extensions

The package includes utility extensions for working with reactive streams:

```dart
import 'package:local_data_source/local_data_source.dart';

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
| **Strategy** | `LocalDataSource` interface + engine implementations | Swap database engine without changing consumer code |
| **Factory** | `LocalDataSourceFactory` | Unified creation with sealed config type matching |
| **Adapter** | `DataModelAdapter<T>` + `NativeCollectionAccessor<T>` | Bridge between domain models and storage |
| **Repository** | Each engine implementation | Encapsulates all data access behind a single contract |
| **Singleton** | `LocalDataSourceFactory._instance` | Single database instance across the app |
| **Builder** | `QueryBuilder<T>` chain | Fluent query construction with deferred execution |
| **Sealed Class** | `LocalDataSourceConfig` / Exceptions | Exhaustive compile-time checked type hierarchies |

---

## Folder Structure

```
local_data_source/
├── pubspec.yaml
├── lib/
│   ├── local_data_source.dart                     # Public barrel export
│   └── src/
│       ├── core/
│       │   ├── local_data_source.dart             # Base abstract interface
│       │   ├── local_data_source_config.dart      # Unified configuration (sealed)
│       │   ├── local_data_source_factory.dart     # Factory entry point
│       │   ├── data_model.dart                    # Serialization contract
│       │   ├── native_collection_accessor.dart    # Native engine access interface
│       │   ├── query_builder.dart                 # Abstract + in-memory query builder
│       │   ├── exceptions.dart                    # Sealed exception hierarchy
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
│       │       └── isar_kv_entry.dart             # Internal @collection for KV ops
│       └── extensions/
│           └── stream_extensions.dart             # Reactive stream utilities
└── example/
    ├── hive_example.dart                          # Generic path with Hive
    ├── isar_example.dart                          # Generic path with Isar
    ├── hive_native_example.dart                   # Native TypeAdapter example
    ├── isar_native_example.dart                   # Native @collection example
    ├── isar_raw_query_example.dart                # Raw Isar instance example
    └── swap_engine.dart                           # Engine swapping demo
```

---

## FAQ

<details>
<summary><strong>Can I use this in a pure Dart project (no Flutter)?</strong></summary>

Yes, but you will need to provide the directory path manually instead of using `path_provider`. The core interface and Hive engine work in pure Dart. Isar also supports pure Dart with manual library setup.
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
LocalDataSourceConfig.isar(
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

This is intentionally not part of the `LocalDataSource` interface to maintain abstraction.
</details>

<details>
<summary><strong>Is this thread-safe?</strong></summary>

Yes. Both Hive and Isar handle concurrent access internally. The package uses `async/await` throughout and avoids shared mutable state beyond the singleton instance.
</details>

<details>
<summary><strong>What happens if I call methods before init()?</strong></summary>

A `DataSourceNotInitializedException` is thrown immediately. Always call `LocalDataSourceFactory.create()` before accessing the database.
</details>

<details>
<summary><strong>How do I encrypt my data?</strong></summary>

With Hive, pass an encryption config:

```dart
LocalDataSourceConfig.hive(
  directory: dir.path,
  encryption: HiveEncryptionConfig(key: mySecureKey),
);
```

Isar Community does not support encryption natively. You can encrypt at the application layer using the `DataModelAdapter<T>` serialization step.
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
