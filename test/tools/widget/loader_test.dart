import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/mypayment/ui/pages/pay_page/qr_code.dart';
import 'package:titan/tools/ui/widgets/loader.dart';

import '../../shared/app_scaffold.dart';

/// `Loader`'s size ceiling.
///
/// The Loader derived its size from `constraints.biggest.shortestSide`, so
/// wherever it was handed a page-sized box it grew to fill it: the boot
/// screen (`LoadingPage`'s `Scaffold(body: Loader())`), every `AsyncChild`
/// page body and both auto-loader builders. On the 800x600 shell that is a
/// 600px spinner; on a 360x640 phone, 360px.
///
/// The clamp keeps the size-derived behaviour (small boxes still get a small
/// spinner) and puts a ceiling on the top end.
///
/// The two page-level guards live in their own files: `others/widget/
/// loading_page_test.dart` for the boot screen, and `mypayment/integration/
/// mypayment_main_page_loading_test.dart` for the account card. Both are
/// needed because each leaks differently — LoadingPage navigates from
/// `build`, and qlevar_router keeps the active branch in process-global state
/// that survives a `ProviderContainer` swap — so a router test sharing a file
/// with either of them comes back rendering somebody else's page.
void main() {
  /// Pumps [child] on a [surface] screen, optionally boxed into [box], and
  /// returns the size of the rendered Loader.
  Future<Size> pumpLoader(
    WidgetTester tester,
    Widget child, {
    Size? box,
    double surface = 360,
    double surfaceHeight = 640,
  }) async {
    tester.view.physicalSize = Size(surface, surfaceHeight);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: box == null
                ? child
                : SizedBox.fromSize(size: box, child: child),
          ),
        ),
      ),
    );
    return tester.getSize(
      find.descendant(of: find.byType(Loader), matching: find.byType(SizedBox)),
    );
  }

  testWidgets('a page-sized box does not grow the spinner past the ceiling', (
    tester,
  ) async {
    // The LoadingPage case: a bare Loader as a Scaffold body.
    final size = await pumpLoader(tester, const Loader());

    expect(size, const Size(64, 64));
    expect(size.shortestSide, lessThanOrEqualTo(Loader.defaultMaxSize));
  });

  testWidgets('an 80%-of-screen box is capped, not scaled', (tester) async {
    // The idiom behind the pay page's QR placeholder and the raffle ticket's
    // scan code: SizedBox(width: screenWidth * 0.8, height: screenWidth * 0.8)
    // around a bare Loader. On a 360 phone that box is 288px; on the desktop
    // web build, 1920 * 0.8 = 1536px — a spinner wider than the screen.
    final size = await pumpLoader(
      tester,
      const Loader(),
      box: const Size(1536, 1536),
    );

    expect(size, const Size(64, 64));
  });

  testWidgets('a wide desktop box is capped too, not just a phone', (
    tester,
  ) async {
    // The shortest side here is 1080: without the ceiling this is a
    // 1080px spinner on the desktop web target.
    final size = await pumpLoader(
      tester,
      const Loader(),
      surface: 1920,
      surfaceHeight: 1080,
    );

    expect(size, const Size(64, 64));
  });

  testWidgets('a small box still shrinks the spinner', (tester) async {
    // The WaitingButton case: the Loader replaces a button's child, so it must
    // stay small enough for the button rather than filling it.
    final size = await pumpLoader(
      tester,
      const Loader(),
      box: const Size(40, 40),
    );

    expect(size, const Size(40, 40));
  });

  testWidgets('unbounded constraints fall back to the small default', (
    tester,
  ) async {
    // Inside a scroll view there is no box size to derive from.
    final size = await pumpLoader(
      tester,
      const SingleChildScrollView(child: Loader()),
    );

    expect(size, const Size(Loader.fallbackSize, Loader.fallbackSize));
  });

  testWidgets('a caller-supplied ceiling is honoured', (tester) async {
    final size = await pumpLoader(tester, const Loader(maxSize: 12));

    expect(size, const Size(12, 12));
  });

  testWidgets('a ceiling larger than the box still yields the box size', (
    tester,
  ) async {
    final size = await pumpLoader(
      tester,
      const Loader(maxSize: 500),
      box: const Size(30, 100),
    );

    expect(size, const Size(30, 30));
  });

  group('at the real call sites', () {
    late IntegrationScaffold scaffold;

    setUp(() {
      scaffold = IntegrationScaffold();
      scaffold.shellSetUp();
    });

    testWidgets('the pay page QR placeholder is capped on phone and desktop', (
      tester,
    ) async {
      // QrCode holds its Loader in SizedBox(screenWidth * 0.8) while the
      // signed payload is built. FakeKeyService has no getKeyPair, so the
      // future errors and QrCode's `snapshot.data == null` branch keeps the
      // Loader up for the whole test — which is the state being measured.
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      for (final surface in const [Size(360, 640), Size(1920, 1080)]) {
        await scaffold.pumpWidgetApp(
          tester,
          const QrCode(),
          container,
          surface: surface,
        );
        await settle(tester, frames: 4);

        expect(find.byType(Loader), findsOneWidget);
        final size = tester.getSize(
          find.descendant(
            of: find.byType(Loader),
            matching: find.byType(SizedBox),
          ),
        );
        expect(
          size.shortestSide,
          lessThanOrEqualTo(Loader.defaultMaxSize),
          reason:
              'the QR placeholder must not scale with the screen '
              '($surface): $size',
        );
      }
    });
  });
}
