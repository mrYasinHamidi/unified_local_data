import 'package:test/test.dart';

import 'package:unified_local_data/unified_data_source.dart';

void main() {
  test('UnifiedDataSourceFactory throws when not initialized', () {
    expect(
      () => UnifiedDataSourceFactory.instance,
      throwsStateError,
    );
  });
}
