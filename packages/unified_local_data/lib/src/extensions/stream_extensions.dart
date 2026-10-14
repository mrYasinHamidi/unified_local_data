import 'dart:async';

/// Stream helpers for the watch methods of `UnifiedDataSource`.
extension LocalDataSourceStreamX<T> on Stream<T> {
  /// Emits an event only after [duration] passes without a newer one, and
  /// drops the events in between.
  Stream<T> debounceTime(Duration duration) {
    Timer? timer;
    late StreamController<T> controller;

    controller = StreamController<T>(
      onListen: () {
        final subscription = listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () => controller.add(data));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
        controller.onCancel = () {
          timer?.cancel();
          subscription.cancel();
        };
      },
    );

    return controller.stream;
  }

  /// Skips events equal to the one before them, compared with [equals] or
  /// with `==`.
  Stream<T> distinctUntilChanged([bool Function(T prev, T next)? equals]) {
    T? previous;
    var hasPrevious = false;
    return where((current) {
      if (!hasPrevious) {
        hasPrevious = true;
        previous = current;
        return true;
      }
      final isEqual =
          equals != null ? equals(previous as T, current) : previous == current;
      previous = current;
      return !isEqual;
    });
  }
}
