import 'package:test/test.dart';

import 'package:unified_local_data/unified_local_data.dart';

void main() {
  test('UnifiedDataSourceFactory throws when not initialized', () {
    expect(
      () => UnifiedDataSourceFactory.instance,
      throwsStateError,
    );
  });
}
