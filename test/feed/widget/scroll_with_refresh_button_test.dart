import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/ui/pages/main_page/scroll_with_refresh_button.dart';
import 'package:titan/navigation/providers/navbar_visibility_provider.dart';

import '../../shared/app_scaffold.dart';

/// `ScrollWithRefreshButton` is the feed's scroll listener (only mounted by
/// feed's main page, which its integration tests never scroll through): this
/// drives its whole state machine against a real ListView —
///
///  - the `hasClients` guard fires before a ScrollPosition attaches,
///  - `jumpTo` counts as a programmatic jump (both `||` operands),
///  - downward scrolls hide the navbar, upward ones show it,
///  - two consecutive upward scrolls (>50ms apart, past the 200px floor)
///    reveal the Refresh pill, a downward one hides it again,
///  - tapping the pill runs `onRefresh`,
///  - the clamped bottom and top ends of the list hit their branches.
///
/// The pill's visibility is probed through `AnimatedPositioned.top` (the
/// child stays mounted at opacity 0, so a text finder can't distinguish the
/// two states).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('drives the scroll listener end to end', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var refreshes = 0;

    Widget harness({bool withList = true}) => Stack(
      children: [
        if (withList)
          ListView.builder(
            controller: controller,
            itemCount: 300,
            itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i')),
          ),
        ScrollWithRefreshButton(
          controller: controller,
          onRefresh: () async => refreshes++,
        ),
      ],
    );

    // 1) Listener registered with no ScrollPosition attached yet: the
    //    hasClients guard must swallow that first notification.
    await pumpWidgetAt(
      tester,
      harness(withList: false),
      container: container,
      surface: const ui.Size(600, 1000),
      appFonts: true,
    );
    controller.notifyListeners();
    await settle(tester, frames: 2);
    expect(tester.takeException(), isNull);

    // 2) With the scrollable in place.
    await pumpWidgetAt(
      tester,
      harness(),
      container: container,
      surface: const ui.Size(600, 1000),
      appFonts: true,
    );

    // The target value (not the animated one): -10 parks the pill off-screen;
    // -999 would betray a missing `top` instead of masquerading as parked.
    double pillTop() =>
        tester
            .widget<AnimatedPositioned>(find.byType(AnimatedPositioned))
            .top ??
        -999;

    // The listener gates the upward-scroll count on `DateTime.now()`, which
    // runs on the REAL clock in widget tests (pump only advances fake
    // timers) — so the >50ms gaps need runAsync, not pump.
    Future<void> realDelay([int ms = 60]) =>
        tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

    expect(pillTop(), -10);
    expect(container.read(navbarVisibilityProvider), isTrue);

    // Programmatic jumps: small (short-circuit skips the first operand) and
    // large (first operand short-circuits the second). Both must be ignored.
    controller.jumpTo(100);
    await settle(tester, frames: 2);
    controller.jumpTo(1500);
    await settle(tester, frames: 2);
    expect(controller.position.pixels, 1500);
    expect(tester.takeException(), isNull);

    // Downward scroll (content up): navbar hides, the 200px floor arms.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await realDelay();
    await settle(tester, frames: 2);
    expect(container.read(navbarVisibilityProvider), isFalse);
    expect(pillTop(), -10);

    // First upward scroll: counts, does not reveal yet.
    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await realDelay();
    await settle(tester, frames: 2);
    expect(container.read(navbarVisibilityProvider), isTrue);
    expect(pillTop(), -10);

    // Second consecutive upward scroll: the pill slides in.
    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await realDelay();
    await settle(tester, frames: 10);
    expect(pillTop(), 10);

    // Downward scroll resets and hides it again.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await realDelay();
    await settle(tester, frames: 10);
    expect(pillTop(), -10);

    // Re-arm the pill and tap it: onRefresh runs and the pill withdraws.
    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await realDelay();
    await settle(tester, frames: 2);
    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await realDelay();
    await settle(tester, frames: 10);
    expect(pillTop(), 10);

    await tester.tap(find.text('Refresh'));
    await settle(tester, frames: 10);
    expect(refreshes, 1);
    expect(pillTop(), -10);

    // Reach the clamped bottom with repeated SMALL drags: one giant move
    // would read as a programmatic jump (>500px) and miss the branch. The
    // final event lands exactly on maxScrollExtent with the gesture active.
    for (
      var i = 0;
      i < 80 &&
          controller.position.pixels < controller.position.maxScrollExtent;
      i++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 6);
    expect(controller.position.pixels, controller.position.maxScrollExtent);
    expect(container.read(navbarVisibilityProvider), isFalse);

    // And back to the top the same way: the pixels<=0 branch shows the
    // navbar again.
    for (var i = 0; i < 80 && controller.position.pixels > 0; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 6);
    expect(controller.position.pixels, 0);
    expect(container.read(navbarVisibilityProvider), isTrue);
    expect(tester.takeException(), isNull);
  });
}
