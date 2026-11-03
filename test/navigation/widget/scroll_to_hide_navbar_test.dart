import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/navigation/providers/navbar_visibility_provider.dart';
import 'package:titan/navigation/ui/scroll_to_hide_navbar.dart';

import '../../shared/app_scaffold.dart';

/// `ScrollToHideNavbar` listens to the controller it is handed and toggles the
/// navbar from the scroll DELTA, with two guards that matter to the app:
///
///  * the top of the list always shows the navbar (offset <= 0),
///  * the very end of the list is ignored, so a list that clamps at its max
///    extent does not keep re-hiding the navbar.
///
/// Only the "scrolled back to the top" arm was exercised (by the home shell),
/// so the hide arm and the max-extent guard are pinned here against a real
/// scrolling list.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpList(
    WidgetTester tester, {
    required List<double> heights,
  }) async {
    final container = scaffold.makeContainer();
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await pumpWidgetAt(
      tester,
      SizedBox(
        height: 200,
        child: ScrollToHideNavbar(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            itemCount: heights.length,
            itemBuilder: (context, index) => SizedBox(
              height: heights[index],
              child: Text('row $index', key: ValueKey(index)),
            ),
          ),
        ),
      ),
      container: container,
    );
    return container;
  }

  testWidgets('scrolling down hides the navbar and scrolling back shows it', (
    tester,
  ) async {
    final container = await pumpList(
      tester,
      heights: List<double>.filled(20, 100),
    );
    expect(container.read(navbarVisibilityProvider), isTrue);

    await tester.drag(find.byKey(const ValueKey(0)), const Offset(0, -300));
    await settle(tester, frames: 4);
    expect(container.read(navbarVisibilityProvider), isFalse);

    // Back past the top: the offset clamps at 0, which must SHOW the bar
    // again even though the last notification carried a delta.
    await tester.drag(find.byKey(const ValueKey(3)), const Offset(0, 400));
    await settle(tester, frames: 4);
    expect(container.read(navbarVisibilityProvider), isTrue);
  });

  testWidgets('a list clamped at its end leaves the navbar alone', (
    tester,
  ) async {
    // 400 logical pixels of content in a 200 pixel viewport: a single short
    // drag already reaches maxScrollExtent, and the drag that clamps there is
    // the one the guard has to swallow.
    final container = await pumpList(
      tester,
      heights: List<double>.filled(4, 100),
    );
    expect(container.read(navbarVisibilityProvider), isTrue);

    await tester.drag(find.byKey(const ValueKey(0)), const Offset(0, -900));
    await settle(tester, frames: 4);
    // The one real scroll of the drag hid it...
    expect(container.read(navbarVisibilityProvider), isFalse);

    container.read(navbarVisibilityProvider.notifier).show();
    await tester.pump();

    // ...and the clamped notification at the end must not hide it again.
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await settle(tester, frames: 4);
    expect(container.read(navbarVisibilityProvider), isTrue);
  });
}
