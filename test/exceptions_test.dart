import 'package:flutter_test/flutter_test.dart';
import 'package:unified_local_data/unified_local_data.dart';

void main() {
  test('toString() is plain text', () {
    const withCause = DataSourceReadException('Failed to read', 'boom');
    const withoutCause = DataSourceNotInitializedException();

    expect(withCause.toString(), isNot(contains('\x1B')));
    expect(withoutCause.toString(), isNot(contains('\x1B')));
    expect(
      withCause.toString(),
      'DataSourceReadException: Failed to read (boom)',
    );
  });
}
