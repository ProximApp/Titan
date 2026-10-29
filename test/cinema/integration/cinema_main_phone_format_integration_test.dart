import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart' show QR;
import 'package:titan/cinema/providers/scroll_provider.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/cinema/ui/pages/main_page/main_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The PHONE side of the cinema main page.
///
/// Every other cinema test calls `setWideSurface` (1920x1080), so
/// `isWebFormatProvider` (safe width > 500) is always true there and the
/// page always takes its `ListView.builder` arm — the `PageView.builder`
/// arm, its card `onTap`, the page controller's scroll listener and the
/// `Refresher.onRefresh` body were never executed at all. This file pins a
/// 480x900 surface (≤500 → phone format) and rides the module's one
/// navigation journey (convention 10): the card tap to `/cinema/detail`.
CineSessionComplete session(String id, String name) =>
    CineSessionComplete.empty().copyWith(
      id: id,
      name: name,
      overview: 'A heart-warming tale of $name',
      start: DateTime.now().add(const Duration(days: 3)),
      duration: 7200,
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// One shared setup: two upcoming sessions, no poster (the 404 fallback
  /// the other cinema files use).
  void stubSessions() {
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse([
        session('c-1', 'Blade Runner'),
        session('c-2', 'Akira'),
      ]),
    );
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  }

  Future<ProviderContainer> pumpPhoneMain(WidgetTester tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    // ≤500 logical width → isWebFormatProvider false → PageView arm.
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    stubSessions();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: CinemaRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);
    return container;
  }

  testWidgets('the phone layout pages between sessions and refreshes', (
    tester,
  ) async {
    final container = await pumpPhoneMain(tester);

    expect(find.byType(CinemaMainPage), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Blade Runner'), findsOneWidget);

    // The page controller's listener (setScroll + currentPage) only runs
    // once the PageView actually moves.
    final before = container.read(scrollProvider);
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await settle(tester, frames: 12);
    expect(container.read(scrollProvider), isNot(before));

    // A held downward drag in the header region arms the Refresher; a fast
    // fling does not (same gesture the membership refresh test uses).
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse([session('c-1', 'Blade Runner')]),
    );
    await tester.dragFrom(
      tester.getTopLeft(find.byType(CinemaMainPage)) + const Offset(200, 40),
      const Offset(0, 300),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    verify(() => scaffold.repository.cinemaSessionsGet()).called(2);

    await scaffold.unmountApp(tester);
  });

  testWidgets('tapping a session card opens its detail page', (tester) async {
    await pumpPhoneMain(tester);

    // Page 0 is the only card under the finger: the PageView keeps the rest
    // in the tree but off-screen, so `tap` would warn about a missed hit.
    await tester.tap(find.text('Blade Runner'));
    await settle(tester, frames: 15);

    expect(QR.currentPath, '${CinemaRouter.root}${CinemaRouter.detail}');
    expect(find.text('Blade Runner'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
