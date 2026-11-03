import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/winning_ticket_card.dart';

import '../../shared/app_scaffold.dart';

/// The creation page's LOCK half (`/tombola/detail/creation` with a locked
/// or open raffle): the winning-ticket strip (`WinningTicketUI` had zero
/// coverage), the prize DRAW dialog round trip (success → the winners
/// dialog + quantity zeroed, failure → the error toast), and the open →
/// close raffle flow (lock PATCH + the per-prize draw fan-out + QR.back).
///
/// raffle_creation_integration_test covers the creation-status half of
/// the same page (open dialog, delete prize); this file owns lock/open.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

AppModulesRaffleSchemasRaffleTicketComplete winner(
  String id, {
  String firstname = 'Zoe',
  String name = 'Zorro',
  PrizeSimple? prize,
}) => AppModulesRaffleSchemasRaffleTicketComplete.empty().copyWith(
  id: id,
  packId: 'pack-$id',
  userId: 'user-$id',
  prize: prize ?? PrizeSimple.empty().copyWith(name: 'PS5', raffleId: 'r-1'),
  user: CoreUserSimple.empty().copyWith(
    id: 'user-$id',
    firstname: firstname,
    name: name,
  ),
  packTicket: PackTicketSimple.empty().copyWith(
    id: 'pack-$id',
    raffleId: 'r-1',
    packSize: 1,
    price: 200,
  ),
);

/// [raffleTickets] lands in `tombolaRafflesRaffleIdTicketsGet` — the
/// endpoint TicketsListNotifier.build auto-fires because the helper pins
/// raffleIdProvider before pumping, and WinningTicketNotifier derives its
/// whole list from it (winners = tickets with a prize).
void stubLockData(
  IntegrationScaffold scaffold, {
  required RaffleStatusType status,
  List<AppModulesRaffleSchemasRaffleTicketComplete> raffleTickets = const [],
}) {
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async => chopperListResponse([
      RaffleComplete.empty().copyWith(
        id: 'r-1',
        name: 'Gala',
        groupId: 'group-1',
        description: 'A good cause',
        status: status,
      ),
    ]),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer(
    (_) async => chopperListResponse([
      PrizeSimple.empty().copyWith(
        id: 'prize-1',
        name: 'PS5',
        raffleId: 'r-1',
        quantity: 2,
      ),
    ]),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(<PackTicketSimple>[]));
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdTicketsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(raffleTickets));
  when(
    () => scaffold.repository.tombolaUsersUserIdTicketsGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
  );
  when(() => scaffold.repository.tombolaUsersCashGet()).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleCashComplete>[]),
  );
  when(
    () => scaffold.repository.tombolaUsersUserIdCashGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(
      AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
        userId: 'user-1',
        balance: 1250,
      ),
    ),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdStatsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(RaffleStats.empty().copyWith(ticketsSold: 42)),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdLockPatch(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperResponseVoid());
  when(
    () => scaffold.repository.tombolaPrizesPrizeIdDrawPost(
      prizeId: any(named: 'prizeId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse([winner('drawn', firstname: 'Dan', name: 'Drew')]),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Deep links straight to the creation page like the creation-status
  /// file does: the detail parent is gated by the same pre-seeded admin
  /// flag, and raffleIdProvider pins every derived provider.
  Future<void> pumpCreation(
    WidgetTester tester, {
    RaffleStatusType status = RaffleStatusType.lock,
    List<AppModulesRaffleSchemasRaffleTicketComplete> raffleTickets = const [],
  }) async {
    stubLockData(scaffold, status: status, raffleTickets: raffleTickets);
    final container = scaffold.makeContainer(user: adminUser);
    container.read(raffleIdProvider.notifier).setId('r-1');
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail/creation',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  testWidgets('locked raffles render the winning ticket strip', (tester) async {
    await pumpCreation(tester, raffleTickets: [winner('w-1')]);

    expect(find.byType(WinningTicketUI), findsOneWidget);
    expect(find.text('Tickets gagnants'), findsOneWidget);
    // The prize strip still offers the draw button for un-drawn prizes.
    expect(find.text('Tirer'), findsOneWidget);
    expect(find.text('Tiré'), findsNothing);
  });

  testWidgets('drawing a prize confirms, POSTs, and lists the winners', (
    tester,
  ) async {
    await pumpCreation(tester, raffleTickets: [winner('w-1')]);

    await tester.tap(find.text('Tirer'));
    await settle(tester, frames: 16);
    expect(find.text('Tirage'), findsOneWidget);
    expect(find.text('Tirer le gagnant de ce lot ?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 24);

    verify(
      () =>
          scaffold.repository.tombolaPrizesPrizeIdDrawPost(prizeId: 'prize-1'),
    ).called(1);
    // Quantity hit zero locally: the strip flipped to the drawn state.
    expect(find.text('Tiré'), findsOneWidget);
    expect(find.text('Tirer'), findsNothing);
    // The winners dialog is fed the DRAWN list from the POST response —
    // one winner here, so the singular title; the seeded winner stays in
    // the strip card behind the dialog.
    expect(find.text('Gagnant'), findsOneWidget);
    expect(find.text('Dan Drew'), findsOneWidget);
  });

  testWidgets('a failed draw keeps the strip and shows the error toast', (
    tester,
  ) async {
    await pumpCreation(tester, raffleTickets: [winner('w-1')]);
    // AFTER pumpCreation: its shared stub answers the draw with success,
    // and this test swaps in the failure the error branch must survive.
    when(
      () => scaffold.repository.tombolaPrizesPrizeIdDrawPost(
        prizeId: any(named: 'prizeId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopper.Response<List<AppModulesRaffleSchemasRaffleTicketComplete>>(
            http.Response('{"detail":"boom"}', 400),
            null,
            error: 'boom',
          ),
    );

    await tester.tap(find.text('Tirer'));
    await settle(tester, frames: 16);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 24);

    verify(
      () =>
          scaffold.repository.tombolaPrizesPrizeIdDrawPost(prizeId: 'prize-1'),
    ).called(1);
    // No quantity change, no winners dialog — and the toast explains why.
    expect(find.text('Tirer'), findsOneWidget);
    expect(find.text('Tiré'), findsNothing);
    expect(find.text('Error during drawing'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('closing an open raffle LOCKs it, draws prizes, steps back', (
    tester,
  ) async {
    await pumpCreation(tester, status: RaffleStatusType.open);

    await tester.tap(find.text('Close'));
    await settle(tester, frames: 16);
    expect(find.text('Close raffle'), findsOneWidget);
    expect(
      find.text(
        'You are going to close the raffle, users will no longer be able to buy tickets. Are you sure you want to continue?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 24);

    verify(
      () =>
          scaffold.repository.tombolaRafflesRaffleIdLockPatch(raffleId: 'r-1'),
    ).called(1);
    // The lock branch fans a draw out to every prize of this raffle.
    verify(
      () =>
          scaffold.repository.tombolaPrizesPrizeIdDrawPost(prizeId: 'prize-1'),
    ).called(1);
    expect(QR.currentPath, '/tombola/detail');
  });
}
