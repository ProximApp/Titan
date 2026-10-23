import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/pack_ticket_provider.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';

import '../../shared/app_scaffold.dart';
import '../raffle_fixtures.dart';

/// The add-edit pack-ticket page (`/tombola/detail/creation/
/// add_edit_pack_ticket`, 61 lines at 0%): the LAST of the creation page's
/// add/edit surfaces with no test at all — the prize page had one, the pack
/// ticket had none.
///
/// Own file for the deep-link rules (conventions 10/11): a deep link to this
/// nested route wedges when an earlier deep link to a different path has run
/// in the same isolate, so the journeys that REACH this page by tapping the
/// creation page's ticket strip live in
/// raffle_creation_edit_flows_integration_test.dart.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

PackTicketSimple packTicket({
  String id = 'pt-1',
  int price = 25,
  int packSize = 10,
}) => PackTicketSimple.empty().copyWith(
  id: id,
  price: price,
  packSize: packSize,
  raffleId: 'r-1',
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpPackPage(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-1');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation/add_edit_pack_ticket',
      pumpAndSettle: false,
    );
    // The deferred page lands at a variable frame; wait for the form.
    for (
      var i = 0;
      i < 40 && find.byType(TextFormField).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(QR.currentPath, '/tombola/detail/creation/add_edit_pack_ticket');
    expect(find.byType(TextFormField), findsNWidgets(2));
  }

  Future<void> submit(WidgetTester tester) async {
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Add').last);
    await tester.tap(find.text('Add').last);
    await settle(tester, frames: 20);
  }

  testWidgets('the add form posts a new pack ticket', (tester) async {
    // The cold deep link: nothing pre-seeds the pack list, because the page
    // must work from a bare URL — that is the path this file exists to prove.
    stubCreationData(scaffold);
    when(
      () =>
          scaffold.repository.tombolaPackTicketsPost(body: any(named: 'body')),
    ).thenAnswer(
      (inv) async => chopperResponse<PackTicketSimple>(
        PackTicketSimple.empty().copyWith(
          id: 'pt-new',
          price: (inv.namedArguments[#body] as PackTicketBase).price,
          packSize: (inv.namedArguments[#body] as PackTicketBase).packSize,
          raffleId: 'r-1',
        ),
      ),
    );

    await pumpPackPage(tester);
    expect(find.text('Nombre de ticket'), findsNWidgets(2));
    expect(find.text('Prix'), findsNWidgets(2));
    // Add mode: the submit button reads 'Add' like the page header.
    expect(find.text('Add'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await settle(tester, frames: 2);
    await submit(tester);

    final captured =
        verify(
              () => scaffold.repository.tombolaPackTicketsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as PackTicketBase;
    expect(captured.packSize, 5);
    expect(captured.price, 10);
    expect(captured.raffleId, 'r-1');
    expect(find.text('Ticket added'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a zero pack size and a zero price are both refused', (
    tester,
  ) async {
    // The cold deep link: nothing pre-seeds the pack list, because the page
    // must work from a bare URL — that is the path this file exists to prove.
    stubCreationData(scaffold);
    when(
      () =>
          scaffold.repository.tombolaPackTicketsPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async => chopperResponse<PackTicketSimple>(
        PackTicketSimple.empty().copyWith(id: 'pt-new'),
      ),
    );

    await pumpPackPage(tester);

    // 0 passes TextEntry's `isInt` check (it only rejects negatives), so
    // the page's own `< 1` validator is what refuses it.
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await settle(tester, frames: 2);
    await submit(tester);
    expect(find.text('Number must be strictly positive'), findsOneWidget);
    verifyNever(
      () =>
          scaffold.repository.tombolaPackTicketsPost(body: any(named: 'body')),
    );

    // A price of 0 clears every field validator and is refused by the
    // submit guard instead, which toasts rather than showing inline.
    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await settle(tester, frames: 2);
    await submit(tester);
    expect(find.text('Price must be greater than 0'), findsOneWidget);
    verifyNever(
      () =>
          scaffold.repository.tombolaPackTicketsPost(body: any(named: 'body')),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a decimal price typed with a comma still posts', (tester) async {
    // The cold deep link: nothing pre-seeds the pack list, because the page
    // must work from a bare URL — that is the path this file exists to prove.
    stubCreationData(scaffold);
    when(
      () =>
          scaffold.repository.tombolaPackTicketsPost(body: any(named: 'body')),
    ).thenAnswer(
      (inv) async => chopperResponse<PackTicketSimple>(
        PackTicketSimple.empty().copyWith(
          id: 'pt-new',
          price: (inv.namedArguments[#body] as PackTicketBase).price,
          packSize: (inv.namedArguments[#body] as PackTicketBase).packSize,
          raffleId: 'r-1',
        ),
      ),
    );

    await pumpPackPage(tester);

    // `isDouble` explicitly ACCEPTS a comma (it rewrites ',' to '.' before
    // parsing), so the field invites "7,50" — the submit handler must then
    // survive the same text, not re-parse it as a plain double.
    await tester.enterText(find.byType(TextFormField).first, '4');
    await tester.enterText(find.byType(TextFormField).at(1), '7,50');
    await settle(tester, frames: 2);
    await submit(tester);

    final captured =
        verify(
              () => scaffold.repository.tombolaPackTicketsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as PackTicketBase;
    expect(captured.packSize, 4);
    expect(captured.price, 8, reason: '7.50 € rounds to 8 euros');
    expect(captured.raffleId, 'r-1');
    expect(find.text('Ticket added'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the edit form prefills and PATCHes the pack ticket', (
    tester,
  ) async {
    // Edit mode is decided by the provider the ticket strip seeds before
    // navigating; the page itself never reads a route argument.
    stubCreationData(scaffold, packTickets: [packTicket()]);
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaPackTicketsPackticketIdPatch(
        packticketId: any(named: 'packticketId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-1');
    container.read(packTicketProvider.notifier).setPackTicket(packTicket());
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation/add_edit_pack_ticket',
      pumpAndSettle: false,
    );
    for (
      var i = 0;
      i < 40 && find.byType(TextFormField).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // Both fields open prefilled from the seeded pack ticket.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '10',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      '25',
    );
    expect(find.text('Edit'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '7');
    await tester.enterText(find.byType(TextFormField).at(1), '30');
    await settle(tester, frames: 2);
    await scaffold.unfocus(tester);
    await tester.ensureVisible(find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 20);

    // The deep link pushed a real history entry, so the success path's
    // QR.back() returns to the creation page that owns the ticket strip.
    expect(QR.currentPath, '/tombola/detail/creation');
    final captured = verify(
      () => scaffold.repository.tombolaPackTicketsPackticketIdPatch(
        packticketId: captureAny(named: 'packticketId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'pt-1');
    final body = captured[1] as PackTicketEdit;
    expect(body.packSize, 7);
    expect(body.price, 30);
    expect(body.raffleId, 'r-1');
    expect(find.text('Ticket edited'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
