import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/raffle_list_provider.dart';
import 'package:titan/raffle/providers/tombola_logos_provider.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/adding_user_card.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/winning_ticket_card.dart';
import 'package:titan/raffle/ui/pages/main_page/raffle_card.dart';
import 'package:titan/raffle/ui/pages/main_page/ticket_card.dart';
import 'package:titan/raffle/ui/pages/raffle_page/buy_type_ticket_card.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../raffle_fixtures.dart';

/// The card-level fallbacks the raffle pages rely on:
/// * a ticket card whose raffle logo is loaded vs. one whose logo load failed,
/// * a raffle card whose stats call answered with an error (no row → zeros),
/// * the winning-ticket card's "firstname name" line,
/// * the buy card's locked label (the only status whose label was unchecked),
/// * the admin "add user" card for a user that has a nickname.
///
/// Dark lines this file's subject still leaves, all proven unreachable:
/// * `providers/winning_ticket_list_provider.dart:43-45` — `drawPrize` reads
///   its own state after awaiting the draw, and `build()` has already
///   scheduled `setData` in a microtask by then, so the state is data; nothing
///   in the notifier ever assigns an error either.
/// * `ui/pages/creation_edit_page/winning_ticket_handler.dart:54-55` — the
///   no-op `onEdit`/`onDelete` closure bodies: `WinningTicketUI` takes both
///   parameters and renders no control that calls them.
/// * `ui/pages/creation_edit_page/winning_ticket_handler.dart:61,63` — the
///   strip's `error:`/`loading:` arms for the same reason as the provider.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ProviderContainer makeContainer({
    List<RaffleComplete> raffles = const [],
    Map<String, AsyncValue<List<Image>>> logos = const {},
    List<dynamic> extra = const [],
  }) {
    final result = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        raffleListProvider.overrideWith(() => FixedRaffleList(AsyncValue.data(raffles))),
        ...extra,
      ],
    );
    addTearDown(result.dispose);
    for (final entry in logos.entries) {
      result.read(tombolaLogosProvider.notifier).setTData(entry.key, entry.value);
    }
    return result;
  }

  testWidgets('a ticket card draws the raffle logo once it is loaded', (
    tester,
  ) async {
    final raffle = raffleFixture('r-1', 'Gala', RaffleStatusType.open);
    final ticket = raffleTicketFixture('t-1', 'r-1');
    final container = makeContainer(
      raffles: [raffle],
      logos: {
        'r-1': AsyncData([
          Image.memory(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
              'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
            ),
          ),
        ]),
      },
    );

    await scaffold.pumpWidgetApp(
      tester,
      TicketWidget(ticket: [ticket], price: 2),
      container,
    );

    expect(
      find.byWidgetPredicate((w) => w is Image),
      findsWidgets,
      reason: 'the loaded logo list was not drawn',
    );
  });

  testWidgets('a ticket card falls back to the placeholder when the logo failed', (
    tester,
  ) async {
    final raffle = raffleFixture('r-1', 'Gala', RaffleStatusType.open);
    final ticket = raffleTicketFixture('t-1', 'r-1');
    final container = makeContainer(
      raffles: [raffle],
      logos: {'r-1': AsyncValue<List<Image>>.error('no logo', StackTrace.empty)},
    );

    await scaffold.pumpWidgetApp(
      tester,
      TicketWidget(ticket: [ticket], price: 2),
      container,
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.cubeTransparent,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a raffle card shows zero stats when the stats call failed', (
    tester,
  ) async {
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdStatsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer((_) async => chopperError<RaffleStats>(500));

    final raffle = raffleFixture('r-1', 'Gala', RaffleStatusType.open);
    final container = makeContainer(raffles: [raffle]);

    await scaffold.pumpWidgetApp(tester, RaffleWidget(raffle: raffle), container);
    await settle(tester, frames: 12);

    // The load answered with an error, so the card renders the empty stats
    // rather than throwing on a missing row.
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('a winning ticket card prints the full name of a nicknamed user', (
    tester,
  ) async {
    final ticket = raffleTicketFixture('t-1', 'r-1').copyWith(
      prize: PrizeSimple.empty().copyWith(id: 'p-1', name: 'Vélo'),
      user: CoreUserSimple.empty().copyWith(
        id: 'user-1',
        firstname: 'Marie',
        name: 'Dupont',
        nickname: 'mimi',
      ),
    );
    final container = makeContainer();

    await scaffold.pumpWidgetApp(
      tester,
      WinningTicketUI(ticket: ticket, onEdit: () {}, onDelete: () async {}),
      container,
    );

    expect(
      autoSizeText(tester, 'Marie Dupont').data,
      'Marie Dupont',
    );
    expect(autoSizeText(tester, 'Vélo').data, 'Vélo');
  });

  testWidgets('a locked raffle card says the raffle is locked', (tester) async {
    final raffle = raffleFixture('r-1', 'Gala', RaffleStatusType.lock);
    final pack = PackTicketSimple.empty().copyWith(
      id: 'pack-1',
      raffleId: 'r-1',
      packSize: 5,
      price: 10,
    );
    final container = makeContainer(raffles: [raffle]);

    await scaffold.pumpWidgetApp(
      tester,
      BuyPackTicket(packTicket: pack, raffle: raffle),
      container,
      locale: const Locale('en', 'US'),
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains('Locked'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the admin add-user card lists a nicknamed user once', (
    tester,
  ) async {
    final user = CoreUserSimple.empty().copyWith(
      id: 'user-7',
      firstname: 'Léa',
      name: 'Petit',
      nickname: 'lp',
    );
    var added = 0;
    final container = makeContainer();

    await scaffold.pumpWidgetApp(
      tester,
      AddingUserCard(user: user, onAdd: () => added++),
      container,
    );

    expect(autoSizeText(tester, 'Léa Petit').data, 'Léa Petit');
    await tester.tap(find.byType(AddingUserCard));
    await settle(tester, frames: 2);
    expect(added, 1);
  });
}
