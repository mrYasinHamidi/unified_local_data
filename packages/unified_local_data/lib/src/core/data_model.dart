import 'typedefs.dart';

/// An optional contract for models that convert themselves to and from
/// JSON. The API uses [DataModelAdapter], not this interface.
abstract interface class DataModel<T> {
  /// This model as a JSON map.
  JsonMap toJson();

  /// A model built from [json].
  T fromJson(JsonMap json);
}

/// Converts [T] to and from JSON for the object methods of
/// `UnifiedDataSource`, such as `putObject` and `getObject`.
final class DataModelAdapter<T> {
  /// Builds a [T] from a JSON map.
  final FromJson<T> fromJson;

  /// Turns a [T] into a JSON map.
  final ToJson<T> toJson;

  /// Creates an adapter from a pair of conversion functions.
  const DataModelAdapter({
    required this.fromJson,
    required this.toJson,
  });
}
