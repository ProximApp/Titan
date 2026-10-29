import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/others/ui/loading_page.dart';
import 'package:titan/tools/ui/widgets/loader.dart';

import '../../shared/app_scaffold.dart';

/// `LoadingPage` is the app's boot screen and is nothing but
/// `Scaffold(body: Loader())` — the one call site where the box the Loader
/// lands in IS the phone. Before the ceiling it drew a spinner the width of
/// whatever device the app booted on: 360px on a phone, 1080px on the desktop
/// web build.
///
/// This file is deliberately its own isolate. LoadingPage navigates from
/// `build` (`QR.to(LoginRouter.root)` and friends) and qlevar_router keeps
/// that navigation in process-global state, so every router test that follows
/// it in the SAME file gets bounced to a "Loading" route and its page never
/// mounts. `flutter test` gives each file a fresh isolate, so the leak stops
/// here — keep the boot-screen guard in this file, not next to the other
/// Loader tests.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the boot spinner no longer fills the phone screen', (
    tester,
  ) async {
    // holdVersionVerifier: resolved, LoadingPage answers its `when` on the
    // first build and routes away, so the spinner is gone before it can be
    // measured.
    final container = scaffold.makeContainer(holdVersionVerifier: true);
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(tester, const LoadingPage(), container);
    await settle(tester, frames: 4);

    expect(find.byType(Loader), findsOneWidget);
    final size = tester.getSize(
      find.descendant(of: find.byType(Loader), matching: find.byType(SizedBox)),
    );
    expect(
      size.shortestSide,
      lessThanOrEqualTo(Loader.defaultMaxSize),
      reason: 'the boot spinner must not fill the viewport: $size',
    );
    // A clamp that collapsed the spinner to nothing would satisfy the
    // assertion above just as well.
    expect(size.shortestSide, greaterThan(0));
  });
}
