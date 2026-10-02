import 'dart:async';
import 'dart:math' as math;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// The MODELS barrel on purpose: the umbrella `openapi.swagger.dart` also
// exports a `Size` ENUM, which shadows dart:ui's Size for every measurement
// in this file (and `show` would drop the generated copyWith extensions).
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/widgets/loader.dart';

import '../../shared/app_scaffold.dart';

/// The mypayment main page's Loader, while it is still loading.
///
/// `AccountCard` sits in the page's own `SizedBox(height: 250, width: <screen
/// width>)` — a BOUNDED box, so its `AsyncChild` took the shortest side and
/// drew a 250px spinner (and a full-width card-shaped hole around it) on
/// every device. The boot screen's equivalent guard is in
/// `others/widget/loading_page_test.dart`.
///
/// This file is deliberately its own isolate. qlevar_router keeps the active
/// route branch in process-global state that survives a ProviderContainer
/// swap, so any router test sharing a file with a page that navigates from
/// `build` — LoadingPage, say — comes back rendering that page's branch
/// instead. With two router tests in one isolate the second one measured the
/// flappybird leaderboard's spinners, not the account card's.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Lets the store list RESOLVE (so the account card mounts) and holds the
  /// wallet call open, so `AccountCard`'s `AsyncChild` keeps its default
  /// loading builder mounted for the whole test.
  ///
  /// The page's other loader (the stores `AsyncChild`) is deliberately NOT
  /// the one under test: it sits in a Column, so its height is unbounded and
  /// it took the 24px fallback even before the fix.
  void stubHangingMypayment() {
    when(
      () => scaffold.repository.mypaymentUsersMeStoresGet(),
    ).thenAnswer((_) async => chopperListResponse(<UserStore>[]));
    when(
      () => scaffold.repository.mypaymentUsersMeWalletGet(),
    ).thenAnswer((_) => Completer<chopper.Response<Wallet>>().future);
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopperResponse(
        TOSSignatureResponse.empty().copyWith(
          acceptedTosVersion: 0,
          latestTosVersion: 0,
        ),
      ),
    );
    when(
      () => scaffold.repository.mypaymentRequestsGet(),
    ).thenAnswer((_) async => chopperListResponse(<Request$>[]));
    when(
      () => scaffold.repository.mypaymentStructuresGet(),
    ).thenAnswer((_) async => chopperListResponse(<Structure>[]));
    when(
      () => scaffold.repository.mypaymentUsersMeWalletHistoryGet(),
    ).thenAnswer((_) async => chopperListResponse(<History>[]));
  }

  testWidgets('the main page keeps its loading spinner sane', (tester) async {
    stubHangingMypayment();
    // 480px, NOT a 360 phone. The account card's two Rows overflow below that
    // under the test harness font, which draws every glyph as a square of the
    // font size: "Personal balance" at 18px measures 288px there against a
    // 260px budget, and the five 12px bold button labels measure 383px
    // against 300px. Loaded with the real Roboto TTFs from the Flutter SDK
    // they measure 137.9px and 211.3px — 92px and 89px of headroom on a 360
    // phone — so the overflows are a harness artifact and MainCardTemplate is
    // left alone. 480 is the narrowest surface where the card measures clean,
    // and the box under test is the card's own SizedBox(height: 250) at every
    // width, so the Loader is capped identically at 360.
    tester.view.physicalSize = const Size(480, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/mypayment',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);

    final sizes = tester
        .widgetList<SizedBox>(
          find.descendant(
            of: find.byType(Loader),
            matching: find.byType(SizedBox),
          ),
        )
        .map((box) => Size(box.width ?? 0, box.height ?? 0))
        .toList();

    expect(sizes, isNotEmpty, reason: 'the page must still be loading');
    expect(sizes.map((s) => s.shortestSide).reduce(math.max), greaterThan(0));
    for (final size in sizes) {
      expect(
        size.shortestSide,
        lessThanOrEqualTo(Loader.defaultMaxSize),
        reason: 'a page-level Loader must not fill the viewport: $size',
      );
    }

    // The wallet never resolves, so the account card's autoDisposed providers
    // are still subscribed when the tree comes down. Riverpod defers
    // autoDispose to a zero-duration Timer, and flutter_test asserts on timers
    // pending after teardown — it never pumps again after this point, so the
    // drain has to happen here.
    await scaffold.unmountApp(tester);
  });
}
