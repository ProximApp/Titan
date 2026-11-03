import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/ticket_ui.dart';
import 'package:titan/raffle/ui/pages/pack_ticket_page/add_edit_pack_ticket_page.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The ticket strip's ONE navigation journey (convention 10): the pencil on
/// `TicketUI` seeds `packTicketProvider` and pushes the deferred
/// `/tombola/detail/creation/add_edit_pack_ticket` route, whose form opens
/// prefilled and PATCHes. The journey needs its own file — a test that
/// navigates to a deferred route after another test's deep link wedges the
/// router stack in the same process.
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

  testWidgets('the pencil opens the prefilled pack-ticket form and PATCHes', (
    tester,
  ) async {
    final ticket = PackTicketSimple.empty().copyWith(
      id: 'pt-1',
      price: 25,
      packSize: 10,
      raffleId: 'r-1',
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
    ).thenAnswer((_) async => chopperListResponse(<PrizeSimple>[]));
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([ticket]));
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
      () => scaffold.repository.tombolaPackTicketsPackticketIdPatch(
        packticketId: any(named: 'packticketId'),
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

    expect(find.byType(TicketUI), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(TicketUI),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
        ),
      ),
    );
    // Deferred route + provider data land at a variable frame; wait for the
    // PAGE (the creation page underneath has a TextFormField of its own, so
    // a bare field count would stop waiting on the first frame).
    for (
      var i = 0;
      i < 60 && find.byType(AddEditPackTicketPage).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(QR.currentPath, '/tombola/detail/creation/add_edit_pack_ticket');
    final fields = find.descendant(
      of: find.byType(AddEditPackTicketPage),
      matching: find.byType(TextFormField),
    );
    // The creation page underneath has its own 'Edit' save button, so the
    // submit label only counts inside the pushed page.
    final submit = find.descendant(
      of: find.byType(AddEditPackTicketPage),
      matching: find.text('Edit'),
    );
    expect(fields, findsNWidgets(2));
    expect(submit, findsOneWidget);
    // The pencil seeded the provider, so the form opens prefilled.
    expect(tester.widget<TextFormField>(fields.first).controller!.text, '10');
    expect(tester.widget<TextFormField>(fields.at(1)).controller!.text, '25');

    await tester.enterText(fields.first, '7');
    await settle(tester, frames: 2);
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, submit);
    await tester.tap(submit);
    await settle(tester, frames: 24);

    final captured = verify(
      () => scaffold.repository.tombolaPackTicketsPackticketIdPatch(
        packticketId: captureAny(named: 'packticketId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'pt-1');
    final body = captured[1] as PackTicketEdit;
    expect(body.packSize, 7);
    expect(body.price, 25);
    expect(body.raffleId, 'r-1');
    expect(find.text('Ticket edited'), findsOneWidget);
    // The success path pops back to the strip that sent us here.
    expect(QR.currentPath, '/tombola/detail/creation');
    await scaffold.drainToast(tester);
  });
}
