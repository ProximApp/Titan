import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';

import 'app_scaffold.dart';

/// The feed timeline hosts EventAction countdowns that schedule a repeating
/// 1-second timer, so pumpAndSettle would time out; pumps are bounded
/// instead.
Future<void> settle(WidgetTester tester, {int frames = 4}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    QR.reset();
    SharedPreferences.setMockInitialValues({});
    scaffold = IntegrationScaffold();
    scaffold.stubInformation();
    // News and association cards load their pictures through this endpoint;
    // an empty 404 body reads as "no image" and falls back to the placeholder.
    when(
      () => scaffold.repository.feedNewsNewsIdImageGet(
        newsId: any(named: 'newsId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  });

  group('Feed main page', () {
    testWidgets(
      'a signed-in user sees the news timeline with titles and status badges',
      (tester) async {
        final now = DateTime.now();
        when(() => scaffold.repository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [
            News.empty().copyWith(
              id: 'n-1',
              title: 'Soirée des clubs',
              module: 'event',
              entity: 'BDE',
              start: now.add(const Duration(days: 3)),
            ),
            News.empty().copyWith(
              id: 'n-2',
              title: 'Week-end intégration',
              module: 'advert',
              entity: 'BDE',
              start: now.subtract(const Duration(days: 1)),
              end: now.add(const Duration(days: 1)),
            ),
          ]),
        );

        await scaffold.pumpApp(
          tester,
          scaffold.makeContainer(),
          initialPath: '/feed',
        );
        await settle(tester, frames: 8);

        // Both cards render (the timeline sorts them by start date).
        expect(find.text('Soirée des clubs'), findsOneWidget);
        expect(find.text('Week-end intégration'), findsOneWidget);
        // The still-running news shows the "Until …" subtitle; MaterialApp
        // resolves en_US (first supported locale), not the fr_FR default of
        // the locale notifier.
        expect(find.textContaining('Until'), findsOneWidget);
        expect(find.text('Ended'), findsNothing);
      },
    );

    testWidgets('an empty feed shows the empty state', (tester) async {
      when(() => scaffold.repository.feedNewsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), <News>[]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/feed',
      );
      await settle(tester);

      expect(find.text('No news available'), findsOneWidget);
    });

    testWidgets('a terminated news is flagged "Ended"', (tester) async {
      final now = DateTime.now();
      when(() => scaffold.repository.feedNewsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [
          News.empty().copyWith(
            id: 'n-1',
            title: 'Ancienne soirée',
            module: 'event',
            entity: 'BDE',
            start: now.subtract(const Duration(days: 3)),
            end: now.subtract(const Duration(days: 2)),
          ),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/feed',
      );
      await settle(tester, frames: 6);

      expect(find.text('Ended'), findsOneWidget);
      expect(find.text('Ongoing'), findsNothing);
    });

    testWidgets(
      'a regular user without associations gets no admin entry point',
      (tester) async {
        when(() => scaffold.repository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), <News>[]),
        );
        when(() => scaffold.repository.associationsMeGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <Association>[]),
        );

        await scaffold.pumpApp(
          tester,
          scaffold.makeContainer(),
          initialPath: '/feed',
        );
        await settle(tester);

        // The admin button only appears for feed admins or association
        // members; CoreUser.empty() has no groups and no associations.
        expect(find.text('Administration'), findsNothing);
      },
    );
  });
}
