import '../../core/local_data_source_config.dart';

final class IsarDataSourceConfig extends LocalDataSourceConfig {
  final List<dynamic> schemas;
  final int maxSizeMiB;
  final bool inspector;

  const IsarDataSourceConfig({
    required super.directory,
    required this.schemas,
    this.maxSizeMiB = 256,
    this.inspector = false,
  }) : super(engine: DatabaseEngine.isar);
}
