import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/ticket_ui.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../raffle_fixtures.dart';

/// The creation page's edit half (`/tombola/detail/creation`): the raffle
/// NAME save (which never reached the wire — `updateRaffle` was a local
/// write only), the ticket strip's delete round trip, and the locked
/// status's winning-ticket strip. The existing creation test covers the
/// open/lock dialogs, the prize strip and the stats.
///
/// No test here leaves the page (convention 10): both journeys to a
/// deferred add/edit form get their own file —
/// `raffle_creation_ticket_edit_journey_` and `raffle_edit_prize_
/// integration_test.dart`.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpCreation(
    WidgetTester tester, {
    RaffleStatusType status = RaffleStatusType.creation,
    List<PackTicketSimple> packTickets = const [],
  }) async {
    stubCreationData(
      scaffold,
      status: status,
      packTickets: packTickets,
      withRaffleTickets: true,
    );
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-1');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    expect(QR.currentPath, '/tombola/detail/creation');
  }

  testWidgets('saving the raffle name PATCHes it to the backend', (
    tester,
  ) async {
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaRafflesRaffleIdPatch(
        raffleId: any(named: 'raffleId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    await pumpCreation(tester);

    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Gala 2026');
    await settle(tester, frames: 2);
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 20);

    final captured = verify(
      () => scaffold.repository.tombolaRafflesRaffleIdPatch(
        raffleId: captureAny(named: 'raffleId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'r-1');
    final body = captured[1] as RaffleEdit;
    expect(body.name, 'Gala 2026');
    expect(body.description, 'A good cause');
  });

  testWidgets('an empty raffle name never leaves the form', (tester) async {
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaRafflesRaffleIdPatch(
        raffleId: any(named: 'raffleId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    await pumpCreation(tester);

    await tester.enterText(find.byType(TextFormField), '');
    await settle(tester, frames: 2);
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 20);

    expect(find.text('This field is required'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.tombolaRafflesRaffleIdPatch(
        raffleId: any(named: 'raffleId'),
        body: any(named: 'body'),
      ),
    );
  });

  testWidgets(
    'deleting a pack ticket confirms through the dialog then DELETEs',
    (tester) async {
      final ticket = PackTicketSimple.empty().copyWith(
        id: 'pt-1',
        price: 25,
        packSize: 10,
        raffleId: 'r-1',
      );
      stubCreationData(
        scaffold,
        packTickets: [ticket],
        withRaffleTickets: true,
      );
      when(
        // ignore: void_checks
        () => scaffold.repository.tombolaPackTicketsPackticketIdDelete(
          packticketId: any(named: 'packticketId'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      scaffold.setWideSurface(tester);
      final container = scaffold.makeContainer(user: adminUser);
      addTearDown(container.dispose);
      container.read(raffleIdProvider.notifier).setId('r-1');
      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/tombola/detail/creation',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 24);

      expect(find.byType(TicketUI), findsOneWidget);
      // Two trash icons live on this page (prize card + ticket card); the
      // ticket strip owns its own.
      await tester.tap(
        find.descendant(
          of: find.byType(TicketUI),
          matching: find.byWidgetPredicate(
            (w) => w is HeroIcon && w.icon == HeroIcons.trash,
          ),
        ),
      );
      await settle(tester, frames: 12);

      expect(find.text('Supprimer le ticket'), findsOneWidget);
      expect(
        find.text('Voulez-vous vraiment supprimer ce ticket?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 16);

      verify(
        () => scaffold.repository.tombolaPackTicketsPackticketIdDelete(
          packticketId: 'pt-1',
        ),
      ).called(1);
      expect(find.text('Ticket deleted'), findsOneWidget);
      await scaffold.drainToast(tester);
    },
  );

  testWidgets('a locked raffle shows the winning-ticket strip instead', (
    tester,
  ) async {
    await pumpCreation(tester, status: RaffleStatusType.lock);

    expect(find.text('Tickets gagnants'), findsOneWidget);
    expect(find.text("Il n'y a pas de ticket gagnant"), findsOneWidget);
    expect(find.byType(TicketUI), findsNothing);
  });
}
