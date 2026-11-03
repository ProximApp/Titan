import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/cinema/providers/session_provider.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';

import '../../shared/app_scaffold.dart';
import '../cinema_fixtures.dart';

/// Two things the cinema route table declares that nothing had ever reached.
///
/// `/cinema/admin/detail` is a SECOND detail route, nested under the admin
/// page: no code navigates to it (`admin_page.dart` and `main_page.dart` both
/// build `/cinema/detail`, the top-level one), so its builder never ran — it is
/// reachable only by typing the URL, which on web is exactly how a bookmarked
/// admin URL arrives. This file is the one place that deep-links it.
///
/// `CinemaRouter.module.getName` / `getDescription` are the two closures the
/// module advertises to the shell: `getName` runs in the navbar and in
/// `all_module_page.dart`, `getDescription` has NO caller in `lib/` at all —
/// so both are asserted here against the real localizations, which is what
/// would break first if a key went missing.
///
/// Convention 10: the whole file rides this one path.
const adminCinemaGroupId = 'ce5f36e6-5377-489f-9696-de70e2477300';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the admin-nested detail route renders the session', (
    tester,
  ) async {
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
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.cinemaSessionsGet()).thenAnswer(
      (_) async => chopperListResponse(const <CineSessionComplete>[]),
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
    container
        .read(sessionProvider.notifier)
        .setSession(
          session('c-1', 'Blade Runner', overview: 'Chase the androids.'),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${CinemaRouter.root}${CinemaRouter.admin}${CinemaRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Blade Runner'), findsOneWidget);
    expect(find.textContaining('Chase the androids'), findsOneWidget);

    // The module's two accessors, against the real bundle. `getName` is what
    // the navbar shows; `getDescription` is declared for the shell but never
    // called anywhere in `lib/` today.
    final context = tester.element(find.text('Blade Runner'));
    final l10n = AppLocalizations.of(context)!;
    expect(CinemaRouter.module.getName(context), l10n.moduleCinema);
    expect(
      CinemaRouter.module.getDescription(context),
      l10n.moduleCinemaDescription,
    );
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
