import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/providers/raffle_list_provider.dart';

import '../raffle_fixtures.dart';

/// A raffle list pinned to one state, so the id provider's build is exercised
/// without a repository (the real notifier fires `tombolaRafflesGet`).
class FixedRaffleList extends RaffleListNotifier {
  FixedRaffleList(this.value);

  final AsyncValue<List<RaffleComplete>> value;

  @override
  AsyncValue<List<RaffleComplete>> build() => value;
}

void main() {
  group('raffleIdProvider', () {
    test('an empty raffle list yields no id instead of throwing', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(
            () => FixedRaffleList(const AsyncValue.data(<RaffleComplete>[])),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Before the fix this was `data.first.id`: `Bad state: No element` on
      // a fresh account, before the first raffle ever loaded.
      expect(container.read(raffleIdProvider), '');
    });

    test('a populated list still selects the first raffle', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(
            () => FixedRaffleList(
              AsyncValue.data([raffleFixture('r-1', 'Gala', null)]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(raffleIdProvider), 'r-1');
    });

    test('a loading list yields no id', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(
            () => FixedRaffleList(const AsyncValue.loading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(raffleIdProvider), '');
    });
  });
}
