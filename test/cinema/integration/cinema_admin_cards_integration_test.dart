import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart' show QR;
import 'package:titan/cinema/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The admin session list's two card callbacks: the trash → confirm dialog →
/// real DELETE round-trip, and the card body → detail. Neither the add nor
/// the edit file touches them (both drive the `+` card instead), so the whole
/// `onDelete`/`onTap` block of `admin_page.dart` was dark.
///
/// The two callbacks are split across tests because deleting removes the
/// card the other test taps. Every test deep-links the SAME path
/// (convention 10).
const adminCinemaGroupId = 'ce5f36e6-5377-489f-9696-de70e2477300';

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

  /// One shared setup: an admin_cinema user, one session, no poster.
  ProviderContainer makeAdmin(WidgetTester tester) {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: adminCinemaGroupId,
            name: 'admin_cinema',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
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
    when(
      () => scaffold.repository.cinemaSessionsSessionIdDelete(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());
    return container;
  }

  testWidgets('the trash opens the confirm dialog and deletes the session', (
    tester,
  ) async {
    final container = makeAdmin(tester);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${CinemaRouter.root}${CinemaRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Blade Runner'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
    );
    await settle(tester, frames: 8);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    verify(
      () => scaffold.repository.cinemaSessionsSessionIdDelete(sessionId: 'c-1'),
    ).called(1);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the session card opens its detail page', (tester) async {
    final container = makeAdmin(tester);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${CinemaRouter.root}${CinemaRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    await tester.tap(find.text('Blade Runner'));
    await settle(tester, frames: 15);

    expect(QR.currentPath, '${CinemaRouter.root}${CinemaRouter.detail}');
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
