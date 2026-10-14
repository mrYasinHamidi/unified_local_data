<p align="center">
  <a href="https://pub.dev/packages/unified_local_data_isar"><img src="https://img.shields.io/pub/v/unified_local_data_isar" alt="pub.dev version" /></a>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

# unified_local_data_isar

The [Isar Community](https://pub.dev/packages/isar_community) engine for [`unified_local_data`](https://pub.dev/packages/unified_local_data).

Your code keeps using the `UnifiedDataSource` API (`put`, `get`, `putObject`, `watch`, `query`, `drop`, …) exactly as with Hive. On top of that, Isar gives you:

- **Real transactions.** `transaction()` runs in one Isar write transaction. Every write inside it joins, and if the action throws, all of them roll back.
- **Your own `@collection` classes** through `native<T>()`, with Isar's indexes and binary speed.
- **Isar's full query language** through `rawInstance`, when you need composite indexes or full-text search.

Isar runs on Android, iOS, macOS, Windows and Linux. It doesn't run on the web; use the Hive engine of `unified_local_data` there.

## Installation

```bash
flutter pub add unified_local_data_isar
```

It depends on `unified_local_data` and re-exports it, so one import covers both:

```dart
import 'package:unified_local_data_isar/unified_local_data_isar.dart';
```

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unified_local_data_isar/unified_local_data_isar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();

  final db = await UnifiedDataSourceFactory.create(
    IsarDataSourceConfig(directory: dir.path),
  );

  await db.put<String>('settings', 'theme', 'dark');
  final theme = await db.get<String>('settings', 'theme');
}
```

| Option | Default | Description |
|---|---|---|
| `directory` | required | Where Isar keeps its database. |
| `schemas` | `[]` | The schemas of your own `@collection` classes. Not needed for the generic API. |
| `maxSizeMiB` | `256` | The most the database may grow to. |
| `inspector` | `false` | Enables the Isar Inspector, for debug builds. |

The rest of the API is described in the [`unified_local_data` README](https://pub.dev/packages/unified_local_data).

## Transactions

```dart
await db.transaction(() async {
  await db.put<int>('cart', 'apples', 3);
  await db.delete('cart', 'pears');
  await db.native<ProductEntity>('products').put(product);
});
```

Every data source call inside the action, every write through `native<T>()`, and a nested `transaction()` all join the same Isar transaction. If the action throws, every write in it rolls back, and the error reaches the caller unchanged.

Don't call `rawInstance.writeTxn()` inside `transaction()`: Isar doesn't nest transactions.

## Native @collection access

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
```

Add `isar_community` to your `dependencies` and `isar_community_generator` and `build_runner` to your `dev_dependencies`.

**Step 2 — Run code generation:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 3 — Pass the schema and use the collection:**

```dart
final db = await UnifiedDataSourceFactory.create(
  IsarDataSourceConfig(
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
```

`query()` filters in memory. For indexed queries, use `rawInstance`.

## Raw instance access

When you need Isar's own query language, with generated `.filter()`, `.sortBy()` and composite index queries, use the Isar instance directly:

```dart
Future<void> advancedIsarQuery(UnifiedDataSource db) async {
  final isar = (db as IsarDataSource).rawInstance;

  final results = await isar.productEntitys
      .filter()
      .categoryEqualTo('Development')
      .and()
      .priceGreaterThan(10.0)
      .sortByPriceDesc()
      .limit(20)
      .findAll();
}
```

> ⚠️ Using `rawInstance` ties your code to Isar. Keep it in the repositories where you have chosen Isar on purpose.

## How the generic API stores data

`put`, `putObject` and the rest keep every entry, as JSON, in one internal Isar collection, keyed by collection name and key. So:

- Lists come back as `List<dynamic>`: read them as `List<dynamic>` and `.cast<T>()`.
- Maps come back as `Map<String, dynamic>`. Store them with `putObject` if your code also runs on Hive, where maps read back differently.
- `drop()` deletes every entry, or every entry of one collection; `clear()` does the same for one collection.

Failures are reported as `DataSourceReadException` and `DataSourceWriteException`, with Isar's error as `cause`. `native<T>()` and `rawInstance` are Isar itself and throw Isar's errors.

## Upgrading from unified_local_data 1.x

The Isar engine used to be part of `unified_local_data`. With version 2.0 it moved here:

1. Depend on `unified_local_data_isar` and import `package:unified_local_data_isar/unified_local_data_isar.dart`.
2. Replace `UnifiedDataSourceConfig.isar(...)` with `IsarDataSourceConfig(...)`. `schemas` is now optional and typed as `List<CollectionSchema<dynamic>>`.

The data format is unchanged, so existing databases open as before.

## License

MIT. See [LICENSE](LICENSE).
