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
      scaffold.makeContainer(failVersionVerifier: true),
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

  testWidgets('KNOWN BUG: the retry button needs TWO taps and shows nothing', (
    tester,
  ) async {
    // `onTap` reads `isConnected` — the value `build` captured — and calls
    // `isInternet()` without awaiting it:
    //
    // ```dart
    // onTap: () async {
    //   isConnectedNotifier.isInternet();
    //   if (isConnected) QR.to(HomeRouter.root);   // stale, false on tap 1
    // },
    // ```
    //
    // The result is a button whose first tap visibly does nothing:
    //
    //   tap 1 - the re-ask SUCCEEDS (the verifier flips to AsyncData and
    //           isConnectedProvider becomes true) and the page rebuilds, but
    //           the closure already tested the old `false`, so no navigation
    //           happens. To the user: nothing at all.
    //   tap 2 - the rebuilt closure sees `true` and navigates to /home.
    //
    // `isInternet()` has exactly one caller in `lib/` (this closure), so
    // nothing else can flip the state while the user sits on the page: the
    // first tap is ALWAYS a no-op when the backend has genuinely come back.
    // `isInternet()` is a single unawaited call, so even a fresh read would
    // race it; the fix is `await isInternet()` and then a fresh
    // `ref.read(isConnectedProvider)`.
    //
    // Left unfixed: it is a UX defect, not a dead end - the user recovers on
    // the second tap. Pinned as two separate assertions because the two taps
    // are the whole bug and a test that only made one would have concluded
    // (wrongly) that the navigation was unreachable.
    final container = scaffold.makeContainer(
      failVersionVerifier: true,
      versionVerifierRecoversOnRetry: true,
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

    // --- tap 1: the re-ask works, the navigation does not ---
    await tester.tap(find.byType(GestureDetector).last);
    await settle(tester, frames: 40);

    expect(
      container.read(versionVerifierProvider),
      isA<AsyncData<CoreInformation>>(),
      reason: 'the first tap really did re-ask the backend',
    );
    expect(container.read(isConnectedProvider), isTrue);
    expect(
      find.byType(NoInternetPage),
      findsOneWidget,
      reason:
          'the first tap must leave the user where they are: the closure read '
          'isConnected before the re-ask resolved. The button gives no visible '
          'feedback whatsoever.',
    );
    expect(QR.currentPath, AppRouter.noInternet);

    // --- tap 2: the rebuilt closure sees true and navigates ---
    await tester.tap(find.byType(GestureDetector).last);
    await settle(tester, frames: 40);

    // The route, not the widget: qlevar pushes /home on top of /no_internet
    // rather than replacing it, so `NoInternetPage` can linger in the
    // navigator's tree after the navigation. `QR.currentPath` is the signal
    // that actually moved, and it is the same signal the middleware test
    // above had to fall back on.
    expect(
      QR.currentPath,
      HomeRouter.root,
      reason:
          'the page rebuilt with isConnected == true during tap 1, so the '
          'second closure is the first one that can navigate. Recovery works; '
          'it just costs the user an extra press on a button that looks '
          'broken.',
    );
    expect(container.read(isConnectedProvider), isTrue);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('KNOWN BUG: while genuinely offline, every tap is a no-op', (
    tester,
  ) async {
    // The other half, and the more common one: the backend has NOT come back,
    // so the state never flips and the closure never sees true. Two taps, no
    // navigation, no error — the button cannot tell the user their press did
    // anything, which is the part a user would actually complain about.
    final container = scaffold.makeContainer(failVersionVerifier: true);
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
