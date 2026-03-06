import 'dart:async';

extension LocalDataSourceStreamX<T> on Stream<T> {
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

  Stream<T> distinctUntilChanged([bool Function(T prev, T next)? equals]) {
    T? previous;
    var hasPrevious = false;
    return where((current) {
      if (!hasPrevious) {
        hasPrevious = true;
        previous = current;
        return true;
      }
      final isEqual = equals != null
          ? equals(previous as T, current)
          : previous == current;
      previous = current;
      return !isEqual;
    });
  }
}