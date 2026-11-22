import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart' show QR;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/admin_button.dart';

import '../../shared/app_scaffold.dart';
import '../cinema_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /cinema lists the upcoming sessions', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse([
        session(
          'c-1',
          'Blade Runner',
          start: DateTime.now().add(const Duration(days: 3)),
        ),
        session(
          'c-2',
          'Akira',
          start: DateTime.now().add(const Duration(days: 5)),
        ),
      ]),
    );
    // Posters auto-load; a 404 falls back to the placeholder asset.
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

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: CinemaRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    // Wide surface → isWebFormat → web card layout renders name, date and
    // overview as plain texts.
    expect(find.text('Now showing'), findsOneWidget);
    expect(find.text('Blade Runner'), findsOneWidget);
    expect(find.text('Akira'), findsOneWidget);
    expect(find.textContaining('A heart-warming tale'), findsWidgets);
  });

  testWidgets('the cinema page shows its empty state without sessions', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse(const <CineSessionComplete>[]),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: CinemaRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('No session'), findsOneWidget);
  });

  testWidgets(
    'a poster fetch that fails answers the card with its error icon',
    (tester) async {
      // `SessionCard`'s AutoLoaderChild used to have an errorBuilder nothing
      // could reach: MapNotifier.autoLoad handed the loader future to `then`
      // with no error handler, so a thrown fetch left the entry on
      // AsyncLoading for ever — a spinner in the card and an exception loose
      // in the zone. autoLoad now files the failure under its key, which is
      // what makes this arm live.
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
        (_) async => chopperListResponse([
          session(
            'c-1',
            'Blade Runner',
            start: DateTime.now().add(const Duration(days: 3)),
          ),
        ]),
      );
      when(
        () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
          sessionId: any(named: 'sessionId'),
        ),
      ).thenThrow(StateError('poster bucket unreachable'));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: CinemaRouter.root,
        pumpAndSettle: false,
      );
      await settle(tester, frames: 12);

      // The wide card keeps its ENTIRE layout — name included — inside the
      // AutoLoaderChild's data arm, so a failed poster leaves the error icon
      // and nothing else. The card is still on screen, which is what the tap
      // target and the session list depend on.
      expect(
        find.ancestor(
          of: find.byType(HeroIcon),
          matching: find.byType(GestureDetector),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the admin card opens the session manager', (tester) async {
    // The Admin button only exists for a cinema admin, and its onTap (navigate
    // to `/cinema/admin` and remember the page index) had never been tapped.
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: 'ce5f36e6-5377-489f-9696-de70e2477300',
            name: 'admin_cinema',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse([session('c-1', 'Blade Runner')]),
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

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: CinemaRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.byType(AdminButton), findsOneWidget);
    await tester.tap(find.byType(AdminButton));
    for (
      var i = 0;
      i < 20 && QR.currentPath != '${CinemaRouter.root}${CinemaRouter.admin}';
      i++
    ) {
      await settle(tester, frames: 4);
    }

    expect(QR.currentPath, '${CinemaRouter.root}${CinemaRouter.admin}');
    expect(tester.takeException(), isNull);
  });
}
