import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/prize_card.dart';
import 'package:titan/raffle/ui/pages/prize_page/add_edit_prize_page.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The prize strip's ONE navigation journey (convention 10): the pencil on
/// `PrizeCard` seeds `prizeProvider` and pushes the deferred
/// `/tombola/detail/creation/add_edit_prize` route, whose form opens
/// prefilled and PATCHes. The existing add-prize file covers only CREATE
/// mode on that page; the edit branch (prefilled controllers, `isEdit`,
/// `updatePrize`) had never been reached from anywhere.
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

  testWidgets('the pencil opens the prefilled prize form and PATCHes', (
    tester,
  ) async {
    final prize = PrizeSimple.empty().copyWith(
      id: 'prize-1',
      name: 'PS5',
      description: 'Old description',
      raffleId: 'r-1',
      quantity: 2,
    );
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse([
        RaffleComplete.empty().copyWith(
          id: 'r-1',
          name: 'Gala',
          groupId: 'group-1',
          status: RaffleStatusType.creation,
        ),
      ]),
    );
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([prize]));
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
    when(
      // ignore: void_checks
      () => scaffold.repository.tombolaPrizesPrizeIdPatch(
        prizeId: any(named: 'prizeId'),
        body: any(named: 'body'),
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

    expect(find.byType(PrizeCard), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(PrizeCard),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
        ),
      ),
    );
    // The creation page underneath stays mounted, so wait for the pushed
    // page itself before measuring its fields.
    for (
      var i = 0;
      i < 60 && find.byType(AddEditPrizePage).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(QR.currentPath, '/tombola/detail/creation/add_edit_prize');
    final fields = find.descendant(
      of: find.byType(AddEditPrizePage),
      matching: find.byType(TextFormField),
    );
    expect(fields, findsNWidgets(3));
    expect(tester.widget<TextFormField>(fields.first).controller!.text, '2');
    expect(tester.widget<TextFormField>(fields.at(1)).controller!.text, 'PS5');
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller!.text,
      'Old description',
    );
    // The creation page underneath keeps its own 'Edit' save button, so
    // both labels only count inside the pushed page.
    final page = find.byType(AddEditPrizePage);
    final submit = find.descendant(of: page, matching: find.text('Edit'));
    expect(
      find.descendant(of: page, matching: find.text('Add')),
      findsOneWidget,
    );
    expect(submit, findsOneWidget);

    await tester.enterText(fields.at(1), 'PS6');
    await settle(tester, frames: 2);
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, submit);
    await tester.tap(submit);
    await settle(tester, frames: 24);

    final captured = verify(
      () => scaffold.repository.tombolaPrizesPrizeIdPatch(
        prizeId: captureAny(named: 'prizeId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'prize-1');
    final body = captured[1] as PrizeEdit;
    expect(body.name, 'PS6');
    expect(body.description, 'Old description');
    expect(body.quantity, 2);
    expect(body.raffleId, 'r-1');
    expect(find.text('Ticket edited'), findsOneWidget);
    expect(QR.currentPath, '/tombola/detail/creation');
    await scaffold.drainToast(tester);
  });
}
