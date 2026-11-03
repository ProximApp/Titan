import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/tools/ui/styleguide/navbar.dart';

import '../../shared/app_scaffold.dart';

Module _module(String root, String name) =>
    Module(getName: (_) => name, getDescription: (_) => '', root: root);

/// The floating navbar had no test at all: the path-driven routeIndex
/// effect (including its out-of-range clamp), the slide animation and every
/// text color/weight branch, the tap arms and the pointer-down
/// showTemporarily call all ran only by hand.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the navbar follows forwarded paths and answers both tap arms', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    // A path that matches the middle item, set before the first build so
    // the path effect picks it up on mount.
    container.read(pathForwardingProvider.notifier).forward('/vote');

    final taps = <String>[];
    await pumpWidgetAt(
      tester,
      FloatingNavbar(
        items: [
          FloatingNavbarItem(
            module: _module('/feed', 'Feed'),
            onTap: () => taps.add('/feed'),
          ),
          FloatingNavbarItem(
            module: _module('/vote', 'Vote'),
            onTap: () => taps.add('/vote'),
          ),
          FloatingNavbarItem(
            module: _module('/settings', 'Settings'),
            onTap: () => taps.add('/settings'),
          ),
        ],
      ),
      container: container,
      surface: const Size(480, 800),
      frames: 8,
    );

    // The mount effects settled on the forwarded path's index.
    expect(find.text('Vote'), findsOneWidget);

    // Let the initial slide animation run its 300ms so the AnimatedBuilder
    // renders mid-progress and finished frames (both progress halves of the
    // color/weight ternaries).
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 250));
    await settle(tester, frames: 4);

    // Tapping a DIFFERENT item swaps the selection, runs the slide effect
    // and calls the callback on the post-frame.
    await tester.tap(find.text('Feed'));
    await tester.pump(); // the tap lands…
    await tester.pump(const Duration(milliseconds: 150)); // …mid-slide

    // A second tap lands while that slide is still running: the handler
    // stops the controller before restarting from the new position.
    await tester.tap(find.text('Vote'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 250));
    await settle(tester, frames: 4);
    expect(taps, ['/feed', '/vote']);

    // Tapping the SELECTED item again takes the else arm: same-frame call.
    await tester.tap(find.text('Vote'));
    await tester.pump();
    await settle(tester, frames: 4);
    expect(taps, ['/feed', '/vote', '/vote']);

    // A forwarded path outside the items clamps to the last slot and
    // re-runs the path effect with a fresh animation.
    container.read(pathForwardingProvider.notifier).forward('/unknown');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 250));
    await settle(tester, frames: 4);
    expect(taps, ['/feed', '/vote', '/vote']);

    // One last tap starts a slide, then the widget is swapped away MID-
    // animation: the dispose effect's stop() is only reachable this way.
    await tester.tap(find.text('Feed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
