import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/cinema/router.dart';

import '../../shared/app_scaffold.dart';

CineSessionComplete session(String id, String name, Duration until) =>
    CineSessionComplete.empty().copyWith(
      id: id,
      name: name,
      overview: 'A heart-warming tale of $name',
      start: DateTime.now().add(until),
      duration: 7200,
    );

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
        session('c-1', 'Blade Runner', const Duration(days: 3)),
        session('c-2', 'Akira', const Duration(days: 5)),
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
    when(
      () => scaffold.repository.cinemaSessionsGet(),
    ).thenAnswer((_) async => chopperListResponse(<CineSessionComplete>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: CinemaRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('No session'), findsOneWidget);
  });
}
