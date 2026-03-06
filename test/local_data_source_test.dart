import 'package:test/test.dart';

import 'package:local_data_source/local_data_source.dart';

void main() {
  test('LocalDataSourceFactory throws when not initialized', () {
    expect(
      () => LocalDataSourceFactory.instance,
      throwsStateError,
    );
  });
}
