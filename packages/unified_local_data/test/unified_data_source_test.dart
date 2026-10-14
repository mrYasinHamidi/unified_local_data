import 'package:flutter_test/flutter_test.dart';

import 'package:unified_local_data/engine.dart';

/// A stand-in engine that records its lifecycle. Every other member falls
/// through to [noSuchMethod].
class _FakeDataSource implements UnifiedDataSource {
  _FakeDataSource({this.failInit = false});

  final bool failInit;
  bool initialized = false;
  bool disposed = false;

  @override
  Future<void> init() async {
    if (failInit) throw StateError('init failed');
    initialized = true;
  }

  @override
  Future<void> dispose() async => disposed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConfig extends UnifiedDataSourceConfig {
  _FakeConfig({this.failInit = false}) : super(directory: '');

  final bool failInit;
  _FakeDataSource? created;

  @override
  UnifiedDataSource createDataSource() =>
      created = _FakeDataSource(failInit: failInit);
}

void main() {
  tearDown(UnifiedDataSourceFactory.reset);

  test('instance throws before create()', () {
    expect(() => UnifiedDataSourceFactory.instance, throwsStateError);
  });

  test('create() builds the data source from the config and opens it',
      () async {
    final config = _FakeConfig();

    final db = await UnifiedDataSourceFactory.create(config);

    expect(db, same(config.created));
    expect(config.created!.initialized, isTrue);
    expect(UnifiedDataSourceFactory.instance, same(db));
  });

  test('create() disposes the previous instance', () async {
    final first = _FakeConfig();
    await UnifiedDataSourceFactory.create(first);

    await UnifiedDataSourceFactory.create(_FakeConfig());

    expect(first.created!.disposed, isTrue);
  });

  test('a failed create() leaves no instance', () async {
    final first = _FakeConfig();
    await UnifiedDataSourceFactory.create(first);

    await expectLater(
      UnifiedDataSourceFactory.create(_FakeConfig(failInit: true)),
      throwsStateError,
    );

    expect(first.created!.disposed, isTrue);
    expect(() => UnifiedDataSourceFactory.instance, throwsStateError);
  });

  test('reset() disposes the instance and forgets it', () async {
    final config = _FakeConfig();
    await UnifiedDataSourceFactory.create(config);

    await UnifiedDataSourceFactory.reset();

    expect(config.created!.disposed, isTrue);
    expect(() => UnifiedDataSourceFactory.instance, throwsStateError);
  });
}
