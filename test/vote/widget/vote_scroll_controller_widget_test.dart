import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/vote/providers/scroll_controller_provider.dart';

import '../../shared/app_scaffold.dart';

/// The vote page's scroll controller, which drives the navbar hide/show
/// animation from the scroll direction.
///
/// The provider is a family keyed by the animation controller it animates,
/// and its listener is the only thing that runs the animation: a downward
/// scroll hides, an upward scroll shows again.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a downward scroll plays the hide animation and an upward '
      'scroll plays it back', (tester) async {
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 100),
    );
    addTearDown(animation.dispose);
    // Start fully "shown" so both directions have somewhere to move.
    animation.value = 1;

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);
    final controller = container.read(scrollControllerProvider(animation));
    addTearDown(controller.dispose);

    await pumpWidgetAt(
      tester,
      ListView.builder(
        controller: controller,
        itemCount: 40,
        itemBuilder: (context, index) =>
            SizedBox(height: 100, child: Text('row $index')),
      ),
      container: container,
      surface: const ui.Size(400, 600),
    );

    // Downward: the reverse arm of the listener. The first pump starts the
    // controller, so the animation needs a second one to run out.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(animation.value, 0);

    // Upward: the forward arm.
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(animation.value, 1);
    expect(tester.takeException(), isNull);
  });
}
