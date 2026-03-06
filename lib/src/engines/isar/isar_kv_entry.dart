import 'package:isar_community/isar_community.dart';

part 'isar_kv_entry.g.dart';

@collection
class IsarKvEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String compositeKey;

  @Index()
  late String collection;

  late String key;

  late String value;
}
