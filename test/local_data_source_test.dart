import 'package:test/test.dart';

import 'package:unified_local_data/local_data_source.dart';

void main() {
  test('LocalDataSourceFactory throws when not initialized', () {
    expect(
      () => LocalDataSourceFactory.instance,
      throwsStateError,
    );
  });
}
