import 'package:auto_size_text/auto_size_text.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/ui/pages/main_page/raffle_card.dart';
import 'package:titan/raffle/ui/pages/main_page/ticket_card.dart';

import '../../shared/app_scaffold.dart';

/// The raffle main page WITH raffles mounted — the shell test in
/// raffle_integration_test only ever seeded an empty list, because
/// `RaffleWidget` used to wrap every card in its own `RaffleTemplate`
/// (a full Scaffold) and the nested Scaffold threw unbounded-height
/// layout assertions inside the page's scroll view. The card now renders
/// bare, so this file covers what was unreachable: the card's stats
/// load, the three status sections (current/upcoming/past), the ticket
/// grouping branches (plain vs winning vs locked-raffle filter), the
/// card-tap navigation, and the pull-to-refresh reload.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

RaffleComplete raffle(String id, String name, RaffleStatusType? status) =>
    RaffleComplete.empty().copyWith(
      id: id,
      name: name,
      groupId: 'group-1',
      description: 'A good cause',
      status: status,
    );

AppModulesRaffleSchemasRaffleTicketComplete ticket(
  String id,
  String raffleId, {
  int packSize = 1,
  int price = 200,
  PrizeSimple? prize,
}) => AppModulesRaffleSchemasRaffleTicketComplete.empty().copyWith(
  id: id,
  packId: 'pack-$id',
  userId: 'user-1',
  prize: prize,
  packTicket: PackTicketSimple.empty().copyWith(
    id: 'pack-$id',
    raffleId: raffleId,
    packSize: packSize,
    price: price,
  ),
);

/// Everything the page and its cards touch: the raffle list, the user
/// tickets, each card's stats + logo, and the three detail-page loads the
/// card-tap fires before navigating.
void stubMainPageData(
  IntegrationScaffold scaffold, {
  List<RaffleComplete> raffles = const [],
  List<AppModulesRaffleSchemasRaffleTicketComplete> tickets = const [],
}) {
  when(() => scaffold.repository.tombolaRafflesGet())
      .thenAnswer((_) async => chopperListResponse(raffles));
  when(
    () => scaffold.repository.tombolaUsersUserIdTicketsGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(tickets));
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdStatsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(
      RaffleStats.empty().copyWith(ticketsSold: 42, amountRaised: 150),
    ),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdLogoGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer(
    (_) async => chopper.Response<List<int>>(
      http.Response('{"detail": "File does not exist"}', 404),
      [],
      error: 'File does not exist',
    ),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(<PrizeSimple>[]));
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdTicketsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(<PackTicketSimple>[]));
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
}

/// The card uses AutoSizeText (a RichText), so name assertions go through
/// widget predicates instead of find.text.
AutoSizeText autoSizeText(WidgetTester tester, String data) => tester
    .widgetList<AutoSizeText>(find.byWidgetPredicate((w) => w is AutoSizeText))
    .firstWhere(
      (t) => t.data == data,
      orElse: () => throw TestFailure('missing AutoSizeText "$data"'),
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  // Convention: the one navigation journey lives first — qlevar_router
  // drops a mid-test QR.to() to an unmounted route once an earlier test
  // in the isolate has already navigated.
  testWidgets('tapping a raffle card loads its data and opens the detail', (
    tester,
  ) async {
    stubMainPageData(
      scaffold,
      raffles: [raffle('r-1', 'Gala', RaffleStatusType.open)],
    );

    // /tombola/detail sits behind AdminMiddleware(isRaffleAdminProvider).
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: adminUser, userId: 'user-1'),
      initialPath: '/tombola',
    );
    await settle(tester);

    autoSizeText(tester, 'Gala');
    await tester.tap(find.byType(RaffleWidget));
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/tombola/detail');
    // The card fired its detail-page loads on tap (AutoLoaderChild has no
    // dedupe guard, so initial-load counts are asserted loosely throughout
    // this file — the point is the wire is hit, not how often).
    verify(
      () =>
          scaffold.repository.tombolaRafflesRaffleIdPrizesGet(raffleId: 'r-1'),
    ).called(greaterThanOrEqualTo(1));
    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
        raffleId: 'r-1',
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('groups raffles into current, upcoming and past sections', (
    tester,
  ) async {
    stubMainPageData(
      scaffold,
      raffles: [
        raffle('r-open', 'Gala now', RaffleStatusType.open),
        raffle('r-soon', 'Gala soon', RaffleStatusType.creation),
        raffle('r-past', 'Gala past', RaffleStatusType.lock),
      ],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        userId: 'user-1',
      ),
      initialPath: '/tombola',
    );
    await settle(tester);

    expect(find.text('Current raffles'), findsOneWidget);
    expect(find.text('Upcoming raffles'), findsOneWidget);
    expect(find.text('Past raffles'), findsOneWidget);
    autoSizeText(tester, 'Gala now');
    autoSizeText(tester, 'Gala soon');
    autoSizeText(tester, 'Gala past');
    // Each card pulled its own stats through the shared map loader.
    expect(find.text('42'), findsNWidgets(3));
    expect(find.textContaining('150.00'), findsNWidgets(3));
    verify(
      () => scaffold.repository.tombolaRafflesRaffleIdStatsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).called(greaterThanOrEqualTo(3));
  });

  testWidgets('sums plain tickets, keeps winners, drops locked ones', (
    tester,
  ) async {
    stubMainPageData(
      scaffold,
      raffles: [
        raffle('r-1', 'Soirée des clubs', RaffleStatusType.open),
        raffle('r-lock', 'Old gala', RaffleStatusType.lock),
      ],
      tickets: [
        // Two plain tickets of the SAME raffle: the sum + price branch.
        ticket('t-1', 'r-1', packSize: 2, price: 400),
        ticket('t-2', 'r-1', packSize: 2, price: 400),
        // A winning ticket: kept and keyed separately (prize != null).
        ticket('t-3', 'r-1', prize: PrizeSimple.empty().copyWith(name: 'PS5')),
        // A plain ticket for a LOCKED raffle: filtered out entirely.
        ticket('t-4', 'r-lock'),
      ],
    );

    // TicketCardBackground runs a repeat() animation: pumpAndSettle would
    // never return with the ticket strip on screen.
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        userId: 'user-1',
      ),
      initialPath: '/tombola',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(find.text('You have no ticket'), findsNothing);
    // Exactly two ticket cards: the grouped plain pair + the winner; the
    // locked raffle's ticket never reached the strip.
    expect(find.byType(TicketWidget), findsNWidgets(2));
    // Two grouped plain tickets at 400/2 each -> 400.00 € and "2 tickets".
    autoSizeText(tester, '400.00 €');
    autoSizeText(tester, '2 tickets');
    // The winning ticket renders its prize instead of a price.
    autoSizeText(tester, 'Winner !');
    autoSizeText(tester, 'PS5');
  });

  testWidgets('pull-to-refresh reloads tickets, raffles and logos', (
    tester,
  ) async {
    var raffleGetCalls = 0;
    var ticketGetCalls = 0;
    stubMainPageData(
      scaffold,
      raffles: [raffle('r-1', 'Gala', RaffleStatusType.open)],
    );
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer((_) async {
      raffleGetCalls++;
      return chopperListResponse([
        raffle('r-1', 'Gala', RaffleStatusType.open),
      ]);
    });
    when(
      () => scaffold.repository.tombolaUsersUserIdTicketsGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {
      ticketGetCalls++;
      return chopperListResponse(
        <AppModulesRaffleSchemasRaffleTicketComplete>[],
      );
    });

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        userId: 'user-1',
      ),
      initialPath: '/tombola',
    );
    await settle(tester);
    expect(raffleGetCalls, 1);
    expect(ticketGetCalls, 1);

    // Overscroll the scroll view from the top to fire the refresh.
    await tester.drag(find.text('Current raffles'), const Offset(0, 400));
    await settle(tester, frames: 24);

    expect(raffleGetCalls, greaterThan(1));
    expect(ticketGetCalls, greaterThan(1));
  });
}
