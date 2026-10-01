import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  News news(String id, String title, enums.NewsStatus status) =>
      News.empty().copyWith(
        id: id,
        title: title,
        entity: 'BDE',
        module: 'event',
        start: DateTime(2026, 10, 10, 20),
        status: status,
      );

  testWidgets(
    'deep link to /feed/event_handling shows pending events and approves one through the real endpoint',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: '59e3c4c2-e60f-44b6-b0d2-fa1b248423bb', // admin_feed
              name: 'admin_feed',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      const pending = 'Soirée phosphorescente';
      const approved = 'Tournoi de baby-foot';
      when(() => scaffold.repository.feedAdminNewsGet()).thenAnswer(
        (_) async => chopperListResponse([
          news('n-1', pending, enums.NewsStatus.waitingApproval),
          news('n-2', approved, enums.NewsStatus.published),
        ]),
      );
      // The card actions also reload the user-facing news list.
      when(
        () => scaffold.repository.feedNewsGet(),
      ).thenAnswer((_) async => chopperListResponse(<News>[]));
      when(
        () => scaffold.repository.feedAdminNewsNewsIdApprovePost(
          newsId: any(named: 'newsId'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/event_handling',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 12);

      expect(find.text('Event Management'), findsOneWidget);
      // The default filter is "pending": only the waiting-approval card shows.
      expect(find.text(pending), findsOneWidget);
      expect(find.text(approved), findsNothing);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      // Approve through the real WaitingButton → POST → the notifier
      // replaces the item in place (status published), dropping it from the
      // pending filter; the card then also reloads the user-facing list.
      await tester.tap(find.text('Approve'));
      await settle(tester, frames: 10);
      verify(
        () => scaffold.repository.feedAdminNewsNewsIdApprovePost(newsId: 'n-1'),
      ).called(1);
      // The card left the pending list.
      expect(find.text(pending), findsNothing);
      // Drain the toast timer the refresh triggers.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );

  testWidgets(
    'the filter chips re-filter the list and the rejected filter shows its empty state',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: '59e3c4c2-e60f-44b6-b0d2-fa1b248423bb',
              name: 'admin_feed',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      when(() => scaffold.repository.feedAdminNewsGet()).thenAnswer(
        (_) async => chopperListResponse([
          news('n-1', 'Pending one', enums.NewsStatus.waitingApproval),
          news('n-2', 'Approved one', enums.NewsStatus.published),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/event_handling',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 12);

      // Switch to "All": both cards render.
      await tester.tap(find.text('All'));
      await settle(tester, frames: 6);
      expect(find.text('Pending one'), findsOneWidget);
      expect(find.text('Approved one'), findsOneWidget);

      // Switch to "Rejected": empty state, no cards.
      await tester.tap(find.text('Rejected'));
      await settle(tester, frames: 6);
      expect(find.text('No rejected events'), findsOneWidget);
      expect(find.text('Pending one'), findsNothing);
    },
  );
}
