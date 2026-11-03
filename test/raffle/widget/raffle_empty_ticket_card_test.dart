import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/raffle_list_provider.dart';
import 'package:titan/raffle/providers/raffle_stats_map_provider.dart';
import 'package:titan/raffle/ui/pages/main_page/raffle_card.dart';
import 'package:titan/raffle/ui/pages/main_page/ticket_card.dart';

import '../../shared/app_scaffold.dart';
import '../raffle_fixtures.dart';

/// A raffle list pinned to one state, so the cards build without a repository.
class FixedRaffleList extends RaffleListNotifier {
  FixedRaffleList(this.value);

  final AsyncValue<List<RaffleComplete>> value;

  @override
  AsyncValue<List<RaffleComplete>> build() => value;
}

/// The empty halves of the raffle cards: neither `ticket[0]` nor
/// `stats.first` has anything to return when the list it reads is empty, and
/// both used to throw during build.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ProviderContainer container({
    AsyncValue<List<RaffleComplete>> raffles = const AsyncValue.data(
      <RaffleComplete>[],
    ),
  }) {
    final result = ProviderContainer(
      overrides: [
        raffleListProvider.overrideWith(() => FixedRaffleList(raffles)),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  testWidgets('a ticket card with no ticket builds its empty state', (
    tester,
  ) async {
    await scaffold.pumpWidgetApp(
      tester,
      const SizedBox(
        width: 360,
        height: 200,
        child: TicketWidget(
          ticket: <AppModulesRaffleSchemasRaffleTicketComplete>[],
          price: 2,
        ),
      ),
      container(),
    );

    // Before the fix `ticket[0].prize` threw a RangeError here.
    expect(find.byType(TicketWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a ticket whose raffle is not in the list still builds', (
    tester,
  ) async {
    await scaffold.pumpWidgetApp(
      tester,
      SizedBox(
        width: 360,
        height: 200,
        child: TicketWidget(
          ticket: [raffleTicketFixture('t-1', 'r-missing')],
          price: 2,
        ),
      ),
      container(),
    );

    // The card used to reach the list with no matching raffle and throw from
    // the lookup; it now falls back to an empty raffle.
    expect(find.byType(TicketWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a raffle card whose stats group is empty still builds', (
    tester,
  ) async {
    final raffle = raffleFixture('r-1', 'Gala', RaffleStatusType.open);
    final raffleContainer = container(raffles: AsyncValue.data([raffle]));
    raffleContainer.read(raffleStatsMapProvider.notifier).state = {
      raffle.id: const AsyncValue.data(<RaffleStats>[]),
    };

    await scaffold.pumpWidgetApp(
      tester,
      SizedBox(width: 360, height: 640, child: RaffleWidget(raffle: raffle)),
      raffleContainer,
    );

    // `stats.first` threw `Bad state: No element` on an empty group.
    expect(find.byType(RaffleWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
