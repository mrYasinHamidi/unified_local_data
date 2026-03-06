import 'typedefs.dart';

abstract interface class DataModel<T> {
  JsonMap toJson();
  T fromJson(JsonMap json);
}

final class DataModelAdapter<T> {
  final FromJson<T> fromJson;
  final ToJson<T> toJson;

  const DataModelAdapter({
    required this.fromJson,
    required this.toJson,
  });
}
