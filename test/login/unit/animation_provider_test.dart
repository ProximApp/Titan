import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/login/providers/animation_provider.dart';

/// `AnimationNotifier` (the login background's controller slot) had no test
/// at all: no controller, no toggle, no value read — every one of its lines
/// sat uncovered. The shape mirrors the navbar's own notifier test: guards
/// first (nothing may throw while the controller is missing), then both
/// directions of `toggle`.
void main() {
  late ProviderContainer container;
  late AnimationNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    notifier = container.read(backgroundAnimationProvider.notifier);
  });

  test('starts without a controller and guards every access', () {
    expect(container.read(backgroundAnimationProvider), isNull);

    // All three accessors have to be inert, not throw.
    notifier.toggle();
    expect(notifier.value, 0);
    expect(notifier.animation, isNull);
    expect(container.read(backgroundAnimationProvider), isNull);
  });

  testWidgets('toggle drives the attached controller both ways', (
    tester,
  ) async {
    // Controllers must be created inside the testWidgets body: their tickers
    // only work inside the tester's FakeAsync zone.
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
    );
    addTearDown(controller.dispose);

    notifier.setController(controller);
    expect(container.read(backgroundAnimationProvider), same(controller));
    expect(notifier.animation, same(controller));
    expect(notifier.value, 0);

    // Not completed yet → forward.
    notifier.toggle();
    await tester.pumpAndSettle();
    expect(controller.isCompleted, true);
    expect(notifier.value, 1);

    // Completed → reverse.
    notifier.toggle();
    await tester.pumpAndSettle();
    expect(controller.isDismissed, true);
    expect(notifier.value, 0);
  });
}
