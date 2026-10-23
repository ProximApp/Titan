import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// The results page (`/tickets/results`, 68 executable lines) with its
/// not-found state, its StatsCard and ticket rows, and its CSV error path.
///
/// The route sits behind AdminMiddleware(canManageTicketEventsProvider)
/// (gate pinned by the scaffold's myStores/storeSellers fakes), and the
/// page reads selectedTicketEventIdProvider — a null id is the not-found
/// branch, a pre-seeded id drives the loads. Every test deep-links the
/// SAME path (convention 10).
///
/// The CSV SUCCESS path is deliberately not driven: downloadFile hands
/// off to file_saver's native save dialog, which does not exist in tests
/// (same limit as the ph download test — it throws UnimplementedError on
/// the Linux CI host), so only the bytes==null error branch is reachable.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubResults(WidgetTester tester) {
    when(() => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'e-1'))
        .thenAnswer(
          (_) async => chopper.Response(
            http.Response('{}', 200),
            models.EventAdmin.empty().copyWith(
              id: 'e-1',
              name: 'Gala',
              ticketsSold: 5,
              ticketsInCheckout: 2,
              quota: 50,
            ),
          ),
        );
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdTicketsGet(
        eventId: 'e-1',
      ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        models.AppCoreTicketsSchemasTicketsTicket.empty().copyWith(
          user: models.CoreUserSimple.empty().copyWith(
            firstname: 'Ada',
            name: 'Lovelace',
          ),
          category: models.Category.empty().copyWith(name: 'Normal'),
          session: models.Session.empty().copyWith(name: 'Vendredi'),
        ),
      ]),
    );
    scaffold.setWideSurface(tester);
  }

  testWidgets('without a selected event the page shows the not-found state', (
    tester,
  ) async {
    final container = sellerContainer(scaffold);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/results',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Ticketing not found'), findsOneWidget);
    // No id: neither admin endpoint is ever asked.
    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdGet(
        eventId: any(named: 'eventId'),
      ),
    );
    verifyNever(
      () => scaffold.repository.ticketsAdminEventsEventIdTicketsGet(
        eventId: any(named: 'eventId'),
      ),
    );
  });

  testWidgets('the results page renders stats and rows, and reloads on pull', (
    tester,
  ) async {
    final container = sellerContainer(scaffold);
    addTearDown(container.dispose);
    stubResults(tester);
    container.read(selectedTicketEventIdProvider.notifier).setId('e-1');

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/results',
      pumpAndSettle: false,
    );
    await settle(tester);

    // Header joins the l10n label with the loaded event name.
    expect(find.text('View results - Gala'), findsOneWidget);

    // StatsCard: both tile labels and the sold/total rich text.
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Tickets sold'), findsOneWidget);
    expect(find.text('In checkout'), findsOneWidget);
    expect(find.text('5 / 50', findRichText: true), findsOneWidget);

    // One ListItemTemplate row per ticket.
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Normal - Vendredi'), findsOneWidget);

    // Pull to refresh reloads the tickets (mount effect + refresh in one
    // verify: mocktail's verify consumes matched calls).
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.ticketsAdminEventsEventIdTicketsGet(
        eventId: 'e-1',
      ),
    ).called(2);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('a failing CSV download toasts the download error', (
    tester,
  ) async {
    final container = sellerContainer(scaffold);
    addTearDown(container.dispose);
    stubResults(tester);
    container.read(selectedTicketEventIdProvider.notifier).setId('e-1');
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdTicketsCsvGet(
        eventId: 'e-1',
      ),
    ).thenThrow(Exception('csv unavailable'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/results',
      pumpAndSettle: false,
    );
    await settle(tester);

    await tester.tap(find.text('Download CSV'));
    await settle(tester, frames: 6);

    // downloadCsv catches the rejection and returns null — the page toasts
    // instead of ever reaching file_saver.
    expect(find.text('Download error'), findsOneWidget);
    await scaffold.drainToast(tester);
    expect(find.text('Download CSV'), findsOneWidget);
  });
}
