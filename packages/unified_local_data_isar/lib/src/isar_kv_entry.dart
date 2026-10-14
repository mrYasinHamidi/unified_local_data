import 'package:isar_community/isar.dart';

part 'isar_kv_entry.g.dart';

/// One entry of the generic API: a value stored under a key in a
/// collection.
@collection
class IsarKvEntry {
  /// Isar's id for the entry.
  Id id = Isar.autoIncrement;

  /// `collection::key`, unique across the database.
  @Index(unique: true, replace: true)
  late String compositeKey;

  /// The collection the entry belongs to.
  @Index()
  late String collection;

  /// The key within [collection].
  late String key;

  /// The value, as JSON.
  late String value;
}
