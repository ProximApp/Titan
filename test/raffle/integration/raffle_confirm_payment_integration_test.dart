import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/pack_ticket_list_provider.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The confirm-payment dialog (`ConfirmPaymentDialog`, 99 uncovered lines)
/// through its only entry point: the BuyPackTicket card on
/// `/tombola/detail` (admin-gated, raffle status must be open — the card's
/// own guard). The dialog carries a 10s REPEATING rotation animation, so
/// every wait is raw pumps (`settle`/pumpFrames); pumpAndSettle would hang
/// forever. The success/failure toasts display through the still-open
/// dialog's context (valid — the pop runs after the toast), unlike the
/// phonebook modal's popped-context bug (#29).
///
/// raffle_integration_test covers the detail page render with an EMPTY
/// pack list and the standalone ticket card; raffle_creation_test covers
/// the admin creation journey — the buy flow, the dialog and its balance
/// guard are new ground here.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

RaffleComplete raffleFixture(RaffleStatusType status) =>
    RaffleComplete.empty().copyWith(
      id: 'r-1',
      name: 'Gala',
      groupId: 'group-1',
      description: 'A good cause',
      status: status,
    );

PackTicketSimple packFixture() => PackTicketSimple.empty().copyWith(
  id: 'pack-1',
  price: 5,
  packSize: 3,
  raffleId: 'r-1',
);

chopper.Response<List<int>> logo404() => chopper.Response<List<int>>(
  http.Response('{"detail": "File does not exist"}', 404),
  [],
  error: 'File does not exist',
);

void stubRaffleOpen(IntegrationScaffold scaffold, {int balance = 500}) {
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async => chopperListResponse([raffleFixture(RaffleStatusType.open)]),
  );
  when(
    () => scaffold.repository.tombolaUsersUserIdCashGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async => chopperResponse(
      AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
        userId: 'user-1',
        balance: balance,
      ),
    ),
  );
  when(
    () => scaffold.repository.tombolaUsersUserIdTicketsGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
  );
  // The dialog's empty-logo branch kicks the real logo fetch.
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdLogoGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => logo404());
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(<PrizeSimple>[]));
  // The pack list the detail page only fetches on pull-to-refresh: the
  // pre-load in pumpDetail seeds the provider from THIS stub.
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse([packFixture()]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Deep links the detail page and pre-loads the pack list the page only
  /// fetches on pull-to-refresh (same not-built-in-build shape as the
  /// invoices pages, ledger #8): the notifier call seeds the exact state a
  /// refresh would produce.
  Future<void> pumpDetail(
    WidgetTester tester, {
    RaffleStatusType status = RaffleStatusType.open,
    int balance = 500,
  }) async {
    stubRaffleOpen(scaffold, balance: balance);
    // Override AFTER stubRaffleOpen for the non-open variant.
    when(
      () => scaffold.repository.tombolaRafflesGet(),
    ).thenAnswer((_) async => chopperListResponse([raffleFixture(status)]));
    final container = scaffold.makeContainer(user: adminUser);
    container.read(raffleIdProvider.notifier).setId('r-1');
    container.read(packTicketListProvider.notifier).loadPackTicketList('r-1');
    // The card row fits since the ledger #31 FittedBox fix; no layout
    // absorbing needed.
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/detail',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  Future<void> pumpFrames(WidgetTester tester, [int frames = 10]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the buy card opens the confirm-payment dialog', (tester) async {
    await pumpDetail(tester);

    expect(find.text('Gala'), findsOneWidget);
    expect(find.textContaining('500.00'), findsOneWidget);
    // Open status: the card shows the buy label.
    expect(find.text('Buy this ticket'), findsOneWidget);    // Ledger #31 fixed: the status label paints INSIDE the card, so the
    // label tap opens the dialog directly.
    await tester.tap(find.text('Buy this ticket'));
    await pumpFrames(tester, 6);

    // The dialog renders the pack price, the pack size and the raffle
    // name (now twice: page header + dialog).
    expect(find.text('5 €'), findsOneWidget);
    expect(find.text('3 tickets'), findsNWidgets(2));
    expect(find.text('Gala'), findsNWidgets(2));
    // Confirm (check) and cancel (x) actions.
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.check),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
      findsOneWidget,
    );

    // The x action pops the dialog without any call; the card's own
    // "3 tickets" label remains.
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
    );
    await pumpFrames(tester, 6);
    expect(find.text('3 tickets'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.tombolaTicketsBuyPackIdPost(
        packId: any(named: 'packId'),
      ),
    );
  });

  testWidgets('an insufficient balance refuses the purchase before the wire', (
    tester,
  ) async {
    await pumpDetail(tester, balance: 2);
    when(
      () => scaffold.repository.tombolaTicketsBuyPackIdPost(
        packId: any(named: 'packId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
    );    // Ledger #31 fixed: the label tap opens the dialog directly.
    await tester.tap(find.text('Buy this ticket'));
    await pumpFrames(tester, 6);
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.check),
    );
    await pumpFrames(tester, 8);

    // The dialog context is still live here (the pop only runs on the
    // purchase paths), so the guard toast renders.
    expect(find.text("Vous n'avez pas assez d'argent"), findsOneWidget);
    verifyNever(
      () => scaffold.repository.tombolaTicketsBuyPackIdPost(
        packId: any(named: 'packId'),
      ),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a confirmed purchase POSTs the pack, drops the balance and '
      'pops', (tester) async {
    await pumpDetail(tester);
    when(
      () => scaffold.repository.tombolaTicketsBuyPackIdPost(
        packId: any(named: 'packId'),
      ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        AppModulesRaffleSchemasRaffleTicketComplete.empty(),
      ]),
    );    // Ledger #31 fixed: the label tap opens the dialog directly.
    await tester.tap(find.text('Buy this ticket'));
    await pumpFrames(tester, 6);
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.check),
    );
    await pumpFrames(tester, 12);

    verify(
      () => scaffold.repository.tombolaTicketsBuyPackIdPost(packId: 'pack-1'),
    ).called(1);
    // The success toast shows through the still-open dialog context before
    // the pop; the dialog is gone (the card's own label remains) and the
    // local balance dropped by the pack price (updateCash -5.0 → 495).
    expect(find.text('Ticket purchased'), findsOneWidget);
    expect(find.text('3 tickets'), findsOneWidget);
    expect(find.textContaining('495.00'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a failed purchase toasts the error and still pops the dialog', (
    tester,
  ) async {
    await pumpDetail(tester);
    when(
      () => scaffold.repository.tombolaTicketsBuyPackIdPost(
        packId: any(named: 'packId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopper.Response<List<AppModulesRaffleSchemasRaffleTicketComplete>>(
            http.Response('{"detail": "sold out"}', 400),
            [],
            error: 'sold out',
          ),
    );    // Ledger #31 fixed: the label tap opens the dialog directly.
    await tester.tap(find.text('Buy this ticket'));
    await pumpFrames(tester, 6);
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.check),
    );
    await pumpFrames(tester, 12);

    expect(find.text('Error during addition'), findsOneWidget);
    // The pop runs on both branches (the card's label remains); the
    // balance is untouched.
    expect(find.text('3 tickets'), findsOneWidget);
    expect(find.textContaining('500.00'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a non-open raffle renders unavailable cards and refuses the '
      'dialog', (tester) async {
    await pumpDetail(tester, status: RaffleStatusType.creation);

    expect(find.text('Unavailable raffle'), findsOneWidget);
    expect(find.text('Buy this ticket'), findsNothing);    // Ledger #31 fixed: the label tap is now hittable; the status guard
    // must keep the dialog closed.
    await tester.tap(find.text('Unavailable raffle'));
    await pumpFrames(tester, 6);
    expect(find.text('3 tickets'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.tombolaTicketsBuyPackIdPost(
        packId: any(named: 'packId'),
      ),
    );
  });
}
