import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/cinema/providers/session_provider.dart';
import 'package:titan/cinema/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /cinema/detail renders the pre-selected session', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
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

    // The detail page renders from client-side state set by the list.
    container
        .read(sessionProvider.notifier)
        .setSession(
          CineSessionComplete.empty().copyWith(
            id: 'c-1',
            name: 'Blade Runner',
            overview: 'A heart-warming tale of replicants',
            start: DateTime(2026, 11, 5, 20, 30),
            duration: 8400,
          ),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${CinemaRouter.root}${CinemaRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Blade Runner'), findsOneWidget);
    expect(find.textContaining('A heart-warming tale'), findsOneWidget);
  });
}
