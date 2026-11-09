import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/auth/providers/is_connected_provider.dart';
import 'package:titan/home/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/others/ui/no_internet_page.dart';
import 'package:titan/router.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

import '../../shared/app_scaffold.dart';

/// The other end of ledger #55's third finding: `AuthenticatedMiddleware`
/// sends an offline user to `NoInternetPage`, and until the harness grew a
/// way to put `versionVerifierProvider` in its error state, that `error:` arm
/// had never run in a test.
///
/// qlevar_router 1.12.4 only processes the init-path middleware chain on the
/// first navigation of an isolate, so — like the other gating files — this one
/// owns exactly one deep link and everything else mounts its page directly.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('an unreachable backend lands the user on the no-internet page', (
    tester,
  ) async {
    // '/' is the one route guaranteed to run the auth middleware chain: it is
    // what the app boots at, and a signed-in user with a working backend
    // would be forwarded from here to /feed. With the verifier in its error
    // state the middleware's `when` takes the `error:` arm and returns
    // `/no_internet` before any of that can happen.
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(scenario: BootScenario.noInternet),
      initialPath: AppRouter.root,
      // NoInternetPage lives in lib/others: landing there is the subject.
      allowedModules: const {'others'},
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    // The rendered page, not `QR.currentPath`: qlevar fires the parent URL
    // update after a redirect, so the path can still report the route that
    // was asked for.
    expect(find.byType(NoInternetPage), findsOneWidget);
    // The feed it would otherwise have shown is genuinely absent, which is
    // what makes this a redirect and not a page that merely also renders.
    expect(find.text('No news available'), findsNothing);
  });

  testWidgets('the retry button re-asks and navigates on the FIRST tap', (
    tester,
  ) async {
    // `onTap` used to read `isConnected` — the value `build` captured, which
    // is `false` precisely because the user is on this page — and to call
    // `isInternet()` without awaiting it. The first tap therefore did nothing
    // visible even when the backend had come back, and only a second tap
    // navigated (ledger #57). It now awaits the re-ask and reads the FRESH
    // value, so one tap is the whole round trip.
    //
    // The three assertions are the three halves of that: the backend really
    // was asked, the state really flipped, and the route really moved.
    final container = scaffold.makeContainer(
      scenario: BootScenario.noInternetRecovers,
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: AppRouter.noInternet,
      // NoInternetPage lives in lib/others: landing there is the subject.
      allowedModules: const {'others'},
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    expect(find.byType(NoInternetPage), findsOneWidget);
    expect(container.read(isConnectedProvider), isFalse);
    expect(QR.currentPath, AppRouter.noInternet);

    await tester.tap(find.byType(GestureDetector).last);
    await settle(tester, frames: 40);

    expect(
      container.read(versionVerifierProvider),
      isA<AsyncData<CoreInformation>>(),
      reason: 'the tap really did re-ask the backend',
    );
    expect(container.read(isConnectedProvider), isTrue);
    // The route, not the widget: qlevar pushes /home on top of
    // /no_internet rather than replacing it, so `NoInternetPage` can linger
    // in the navigator's tree after the navigation — the same reason this
    // file never asserts on the page itself once it has navigated.
    expect(QR.currentPath, HomeRouter.root);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('while genuinely offline, a tap re-asks and stays put', (
    tester,
  ) async {
    // The other half, and the more common one: the backend has NOT come back,
    // so the re-ask still answers "down" and there is nowhere to navigate to.
    // After ledger #57's fix this is the intended answer rather than the
    // stale-closure accident it used to be — what still matters is that the
    // tap neither crashes nor navigates on a guess, so three taps are checked
    // rather than one (a retry loop would only show up on the second pass).
    final container = scaffold.makeContainer(scenario: BootScenario.noInternet);
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: AppRouter.noInternet,
      // NoInternetPage lives in lib/others: landing there is the subject.
      allowedModules: const {'others'},
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    for (var tap = 1; tap <= 3; tap++) {
      await tester.tap(find.byType(GestureDetector).last);
      await settle(tester, frames: 20);
      expect(find.byType(NoInternetPage), findsOneWidget);
      expect(container.read(isConnectedProvider), isFalse);
      expect(container.read(versionVerifierProvider).hasError, isTrue);
    }

    expect(QR.currentPath, AppRouter.noInternet);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
