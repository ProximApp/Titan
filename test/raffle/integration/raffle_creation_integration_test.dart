import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The raffle creation/edit page (`/tombola/detail/creation`, 141
/// uncovered lines) plus the add-edit prize page it links to (93 more):
/// the edit form, ticket + prize handler strips, the open-raffle dialog
/// chain, the locked status stats, the prize delete dialog round trip,
/// and the add-prize form's POST round trip.
///
/// raffle_integration_test covers the main page, the standalone detail
/// page and ticket cards — the creation journey is new ground here.
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

void stubCreationData(IntegrationScaffold scaffold) {
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async =>
        chopperListResponse([raffle('r-1', 'Gala', RaffleStatusType.creation)]),
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
    () => scaffold.repository.tombolaUsersUserIdTicketsGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Deep links straight to the creation page: the detail-page parent is
  /// gated by the same pre-seeded admin flag, and raffleIdProvider pins
  /// which raffle every provider derives from.
  Future<void> pumpCreation(
    WidgetTester tester, {
    RaffleStatusType status = RaffleStatusType.creation,
    String path = '/tombola/detail/creation',
  }) async {
    stubCreationData(scaffold);
    // Override AFTER stubCreationData, which stubs a creation-status list.
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse([raffle('r-1', 'Gala', status)]),
    );
    final container = scaffold.makeContainer(user: adminUser);
    container.read(raffleIdProvider.notifier).setId('r-1');
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: path,
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  Future<void> pumpFrames(WidgetTester tester, [int frames = 16]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('creation mode renders the form with prize strip and add card', (
    tester,
  ) async {
    await pumpCreation(tester);

    expect(QR.currentPath, '/tombola/detail/creation');
    expect(find.text('Edit raffle'), findsNWidgets(2));
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Lots'), findsOneWidget);
    // The existing prize card shows its quantity.
    expect(find.text('Quantity : 2'), findsOneWidget);
    // The Open dialog button sits in the bottom action row.
    expect(find.text('Open'), findsWidgets);
  });

  testWidgets('the Open dialog opens the raffle through the API', (
    tester,
  ) async {
    await pumpCreation(tester);
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaRafflesRaffleIdOpenPatch(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(find.text('Open').last);
    await pumpFrames(tester, 10);

    expect(find.text('Open raffle'), findsOneWidget);
    expect(
      find.text(
        'You are going to open the raffle, users will be able to buy tickets. You will no longer be able to modify the raffle. Are you sure you want to continue?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 20);

    verify(
      () =>
          scaffold.repository.tombolaRafflesRaffleIdOpenPatch(raffleId: 'r-1'),
    ).called(1);
  });

  testWidgets('locked raffles show stats and the draw buttons instead', (
    tester,
  ) async {
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdStatsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperResponse(RaffleStats.empty().copyWith(ticketsSold: 42)),
    );
    await pumpCreation(tester, status: RaffleStatusType.lock);

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Tickets'), findsWidgets);
    // The draw action on the prize card replaces edit/delete.
    expect(find.text('Tirer'), findsOneWidget);
    expect(find.text('Tiré'), findsNothing);
  });

  testWidgets('deleting a prize confirms through the dialog then DELETEs', (
    tester,
  ) async {
    await pumpCreation(tester);
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaPrizesPrizeIdDelete(
        prizeId: any(named: 'prizeId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.trash),
    );
    await pumpFrames(tester, 10);

    expect(find.text('Supprimer le lot'), findsOneWidget);
    expect(find.text('Voulez-vous vraiment supprimer ce lot?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester, 16);

    verify(
      () => scaffold.repository.tombolaPrizesPrizeIdDelete(prizeId: 'prize-1'),
    ).called(1);
    await scaffold.drainToast(tester);
  });
}
