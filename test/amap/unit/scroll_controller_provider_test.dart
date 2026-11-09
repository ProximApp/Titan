import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  testWidgets('scrolling up reveals and scrolling down hides', (tester) async {
    final animation = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 200),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(scrollControllerProvider(animation));

    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller,
          itemCount: 60,
          itemBuilder: (context, index) =>
              SizedBox(height: 100, child: Text('row $index')),
        ),
      ),
    );

    // Dragging up (a downward scroll) is the reverse direction: the bar stays
    // hidden, so the animation has nothing to advance from.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(animation.value, 0);

    // Dragging back down is the forward direction: the animation starts.
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    // The first tick only starts the controller's clock; the second advances it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(animation.value, greaterThan(0));

    // And it retreats again on the next upward drag.
    final before = animation.value;
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(animation.value, lessThan(before));

    // Settle the controller: a ticker still running at the end of a test is a
    // leak, and the harness checks before tear-downs run.
    animation.stop();
    animation.dispose();
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
