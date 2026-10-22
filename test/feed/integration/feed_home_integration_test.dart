import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The feed timeline hosts EventAction countdowns that schedule a repeating
/// 1-second timer, so pumpAndSettle would time out; pumps are bounded
/// instead.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
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
