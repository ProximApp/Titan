import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/mypayment/ui/pages/main_page/flip_card.dart';

import '../../shared/app_scaffold.dart';

/// The main page's wallet card is a two-sided flip driven by horizontal
/// swipes: swiping right forwards the controller (revealing the back), a left
/// swipe reverses it and clears the wallet/history caches.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('swiping flips the card and its back face', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 120),
    );
    addTearDown(controller.dispose);

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      FlipCard(
        front: const Text('FRONT'),
        back: const Text('BACK'),
        controller: controller,
      ),
      container,
    );

    // Closed card: the front face only.
    expect(find.text('FRONT'), findsOneWidget);
    expect(find.text('BACK'), findsNothing);
    expect(controller.value, 0);

    // Swipe right forwards the flip.
    await tester.fling(find.byType(FlipCard), const Offset(300, 0), 1000);
    await settle(tester);
    expect(controller.value, 1);
    expect(find.text('BACK'), findsOneWidget);
    expect(find.text('FRONT'), findsNothing);

    // Swipe left goes back and invalidates the cached wallet and history.
    await tester.fling(find.byType(FlipCard), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(controller.value, 0);
    expect(find.text('FRONT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
