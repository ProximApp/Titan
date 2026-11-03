import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/amap/providers/scroll_controller_provider.dart';

void main() {
  test('scroll controller provider should create a new notifier for each animation controller', () {
    final animationController1 = AnimationController(vsync: TestVSync());
    final animationController2 = AnimationController(vsync: TestVSync());

    final scrollControllerNotifier1 = scrollControllerProvider(
      animationController1,
    );
    final scrollControllerNotifier2 = scrollControllerProvider(
      animationController2,
    );

    expect(scrollControllerNotifier1, isNot(equals(scrollControllerNotifier2)));
    expect(scrollControllerNotifier1, isNot(equals(scrollControllerNotifier2)));
  });
}

class TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return TestTicker(onTick);
  }
}

class TestTicker extends Ticker {
  TestTicker(super.onTick);

  @override
  void stop({bool canceled = true}) {}
}
