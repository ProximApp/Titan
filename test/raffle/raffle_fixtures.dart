import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/providers/raffle_list_provider.dart';
import 'package:titan/raffle/providers/ticket_list_provider.dart';
import 'package:titan/raffle/providers/winning_ticket_list_provider.dart';

import '../shared/app_scaffold.dart';
import '../shared/fixtures.dart' show adminGroupId;

/// Finds the [AutoSizeText] whose data matches: the raffle cards render
/// their labels as AutoSizeText (a RichText), so `find.text` never sees
/// them and assertions go through widget predicates instead.
AutoSizeText autoSizeText(WidgetTester tester, String data) => tester
    .widgetList<AutoSizeText>(find.byWidgetPredicate((w) => w is AutoSizeText))
    .firstWhere(
      (t) => t.data == data,
      orElse: () => throw TestFailure('missing AutoSizeText "$data"'),
    );

/// The raffle admin gate group — the shared main admin group.
const raffleAdminGroupId = adminGroupId;

/// Create a raffle with predictable defaults for raffle-module tests.
RaffleComplete raffleFixture(
  String id,
  String name,
  RaffleStatusType? status,
) => RaffleComplete.empty().copyWith(
  id: id,
  name: name,
  groupId: 'group-1',
  description: 'A good cause',
  status: status,
);

/// Build a raffle administrator with predictable raffle-admin membership.
CoreUser raffleAdminUserFixture({String id = 'user-1'}) =>
    CoreUser.empty().copyWith(
      id: id,
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: raffleAdminGroupId,
          name: 'admin_raffle',
        ),
      ],
    );

/// Build a user-owned raffle ticket with its nested pack ticket; the shape
/// every raffle card and ticket strip renders.
AppModulesRaffleSchemasRaffleTicketComplete raffleTicketFixture(
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

/// Stubs the tombola reads the creation-flow pages share on mount: the
/// raffle list (one raffle), its prizes, its pack tickets, and the current
/// user's tickets. Three files rebuilt this block by hand; [prizes] and
/// [packTickets] carry what each page actually renders. [withRaffleTickets]
/// additionally answers the per-raffle ticket list only the creation-edit
/// shell reads.
void stubCreationData(
  IntegrationScaffold scaffold, {
  RaffleStatusType status = RaffleStatusType.creation,
  List<PrizeSimple> prizes = const [],
  List<PackTicketSimple> packTickets = const [],
  bool withRaffleTickets = false,
}) {
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async => chopperListResponse([raffleFixture('r-1', 'Gala', status)]),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(prizes));
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(packTickets));
  when(
    () => scaffold.repository.tombolaUsersUserIdTicketsGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
  );
  if (withRaffleTickets) {
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdTicketsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
    );
  }
}

/// A raffle list pinned to one state, so a card or provider can be built
/// without a repository (the real notifier fires `tombolaRafflesGet`).
///
/// Shared by every raffle test that needs a fixed list: the moment a second
/// file needs a double, convention 34 moves it here rather than copying it.
class FixedRaffleList extends RaffleListNotifier {
  FixedRaffleList(this.value);

  final AsyncValue<List<RaffleComplete>> value;

  @override
  AsyncValue<List<RaffleComplete>> build() => value;
}

/// A raffle id pinned to one value, so a provider that derives from the
/// selected raffle resolves without a list load.
class FakeRaffleIdNotifier extends RaffleIdProvider {
  FakeRaffleIdNotifier(this.id);

  final String id;

  @override
  String build() => id;
}

/// The current user's tickets pinned to a list, so the winning-ticket
/// derivations and strips build without a repository call.
class FakeTicketsListNotifier extends TicketsListNotifier {
  FakeTicketsListNotifier(this.tickets);

  final List<AppModulesRaffleSchemasRaffleTicketComplete> tickets;

  @override
  AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>> build() =>
      AsyncValue.data(tickets);
}

/// The drawn-ticket list HELD in a state, with the REAL `drawPrize`.
///
/// `WinningTicketNotifier.build` seeds itself from a microtask, so in a test
/// (and in a fast app) the list is data before any draw resumes. A draw that
/// lands while the list is still loading, or after it failed, is exactly what
/// the two `state.when` arms in `drawPrize` answer — and that is only
/// reachable by holding the state still.
class HeldWinningTickets extends WinningTicketNotifier {
  HeldWinningTickets(this.held);

  final AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>> held;

  @override
  AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>> build() => held;
}

/// The drawn-ticket list with a draw that answers whatever a test needs, so
/// the prizes strip's `loading` arm can be walked.
class FakeDrawWinningTickets extends WinningTicketNotifier {
  FakeDrawWinningTickets({
    this.held = const AsyncValue.data(
      <AppModulesRaffleSchemasRaffleTicketComplete>[],
    ),
    required this.draw,
  });

  final AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>> held;
  final AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>> draw;

  @override
  AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>> build() => held;

  @override
  Future<AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>>>
  drawPrize(PrizeSimple prize) async => draw;
}

/// The raffle list pinned to a state whose writes still answer success, so a
/// page can reach the arms it runs AFTER an edit while the list it watched is
/// still loading or has failed.
class FixedRaffleListWithWrite extends FixedRaffleList {
  FixedRaffleListWithWrite(super.value);

  @override
  Future<bool> updateRaffle(RaffleComplete raffle) async => true;
}
