import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/confirm_creation.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/tombola_handler.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The raffle admin page's CREATE flow (`/tombola/admin`): plus → group
/// picker → confirmation dialog → the wire.
///
/// This is the file that pins the biggest defect the cluster surfaced:
/// `createRaffle` was `localAdd` and the dialog refetched immediately after,
/// so "create a raffle" posted NOTHING and erased its own optimistic entry —
/// `tombolaRafflesPost` had no caller in `lib/` at all. The last assertion
/// reads the strip AFTER the refetch, which is where the old code was empty.
///
/// No route navigation happens in this file (convention 10); the dialog's
/// `useAnimationController(..repeat())` also means every pump here is a
/// fixed `settle()` — `pumpAndSettle` would never return.
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

  testWidgets('the confirm dialog really creates the raffle through the API', (
    tester,
  ) async {
    var raffles = <RaffleComplete>[
      RaffleComplete.empty().copyWith(
        id: 'r-0',
        name: 'Tombola : BDE Musique',
        groupId: 'group-0',
        status: RaffleStatusType.creation,
      ),
    ];
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse(List<RaffleComplete>.of(raffles)),
    );
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperResponse<List<CoreGroupSimple>>([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE Info'),
      ]),
    );
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<PrizeSimple>[]));
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<PackTicketSimple>[]));
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdTicketsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
    );
    when(
      () => scaffold.repository.tombolaUsersUserIdTicketsGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
    );
    when(() => scaffold.repository.tombolaRafflesPost(body: any(named: 'body')))
        .thenAnswer((inv) async {
          final body = inv.namedArguments[#body] as RaffleBase;
          final created = RaffleComplete.empty().copyWith(
            id: 'r-new',
            name: body.name,
            groupId: body.groupId,
            status: body.status,
            description: body.description,
          );
          raffles = [...raffles, created];
          return chopperResponse(created);
        });

    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(
      user: adminUser,
      groups: [CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'BDE Info')],
    );
    addTearDown(container.dispose);
    container.read(raffleIdProvider.notifier).setId('r-0');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    expect(find.byType(TombolaHandler), findsOneWidget);
    expect(find.text('Tombola : BDE Musique'), findsOneWidget);

    // Plus in the raffle strip (AccountHandler has one too).
    await tester.tap(
      find.descendant(
        of: find.byType(TombolaHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    await settle(tester, frames: 20);
    expect(find.text('Pour quel groupe ?'), findsOneWidget);

    await tester.tap(find.text('BDE Info').last);
    await settle(tester, frames: 20);
    expect(
      find.text('Voulez vous vraiment créer la tombola : BDE Info'),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ConfirmCreationDialog),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.check,
        ),
      ),
    );
    await settle(tester, frames: 40);

    final captured = verify(
      () => scaffold.repository.tombolaRafflesPost(
        body: captureAny(named: 'body'),
      ),
    ).captured;
    final body = captured.single as RaffleBase;
    expect(body.name, 'Tombola : BDE Info');
    expect(body.groupId, 'g-1');
    expect(body.status, RaffleStatusType.creation);
    expect(body.description, '');

    // The dialog pops itself and the strip re-reads the list — with the old
    // local-only create, that refetch is what wiped the raffle out again.
    expect(
      find.text('Voulez vous vraiment créer la tombola : BDE Info'),
      findsNothing,
    );
    expect(find.text('Tombola : BDE Info'), findsOneWidget);
  });
}
