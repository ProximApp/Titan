import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/providers/raffle_list_provider.dart';
import 'package:titan/raffle/providers/raffle_provider.dart';
import 'package:titan/raffle/providers/ticket_list_provider.dart';
import 'package:titan/raffle/providers/winning_ticket_list_provider.dart';
import 'package:titan/raffle/providers/raffle_stats_map_provider.dart';
import 'package:titan/raffle/providers/user_amount_provider.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../raffle_fixtures.dart';

/// The provider arms the raffle pages fall back on when a load has not
/// answered: an empty derived raffle, an empty stats map, and the balance
/// updater's two refusals (already errored, still loading).
///
/// Every one of them is reached through the notifier's own public API or the
/// provider's derivation — none of them pokes `state` from the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('raffleProvider', () {
    test('answers an empty raffle for an id the list does not carry', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(
            () => FixedRaffleList(
              AsyncValue.data([raffleFixture('r-1', 'Gala', null)]),
            ),
          ),
          raffleIdProvider.overrideWith(
            () => FakeRaffleIdNotifier('r-missing'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final raffle = container.read(raffleProvider);

      expect(raffle.id, RaffleComplete.empty().id);
      expect(raffle.name, RaffleComplete.empty().name);
    });

    test('answers an empty raffle while the list is not data', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(
            () => FixedRaffleList(const AsyncValue.loading()),
          ),
          raffleIdProvider.overrideWith(() => FakeRaffleIdNotifier('r-1')),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(raffleProvider).id, isNot('r-1'));
    });
  });

  group('raffleStatsMapProvider', () {
    test('keys one entry per loaded raffle', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(
            () => FixedRaffleList(
              AsyncValue.data([
                raffleFixture('r-1', 'Gala', null),
                raffleFixture('r-2', 'Loto', null),
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(raffleStatsMapProvider).keys, ['r-1', 'r-2']);
    });

    test('is empty while the raffle list is not data', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(
            () => FixedRaffleList(const AsyncValue.loading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(raffleStatsMapProvider), isEmpty);
    });
  });

  group('userAmountProvider.updateCash', () {
    CoreUser user() => CoreUser.empty().copyWith(id: 'user-1');

    test('refuses while the balance is still loading', () async {
      // A load that never answers: the state stays loading exactly as it does
      // on a slow network, which is when the updater has to refuse.
      when(
        () => scaffold.repository.tombolaUsersUserIdCashGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) =>
            Completer<
                  chopper.Response<AppModulesRaffleSchemasRaffleCashComplete>
                >()
                .future,
      );

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(scaffold.repository),
          userProvider.overrideWithValue(user()),
        ],
      );
      addTearDown(container.dispose);

      // build() fires loadCashByUser and returns loading, so a read straight
      // after the notifier is created finds the state it has to refuse.
      final notifier = container.read(userAmountProvider.notifier);
      await notifier.updateCash(50);

      final state = container.read(userAmountProvider);
      expect(
        state,
        isA<AsyncError<AppModulesRaffleSchemasRaffleCashComplete>>(),
      );
      expect((state.error as Object).toString(), contains('while loading'));
    });

    test('keeps the load error when the balance never arrived', () async {
      when(
        () => scaffold.repository.tombolaUsersUserIdCashGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async =>
            chopperError<AppModulesRaffleSchemasRaffleCashComplete>(500),
      );

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(scaffold.repository),
          userProvider.overrideWithValue(user()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userAmountProvider.notifier);
      final loaded = await notifier.loadCashByUser('user-1');
      expect(
        loaded,
        isA<AsyncError<AppModulesRaffleSchemasRaffleCashComplete>>(),
      );

      await notifier.updateCash(50);

      final state = container.read(userAmountProvider);
      expect(
        state,
        isA<AsyncError<AppModulesRaffleSchemasRaffleCashComplete>>(),
      );
      expect((state.error as Object).toString(), isNot(contains('while')));
    });
  });

  group('raffleListProvider.deleteRaffle', () {
    test('drops the raffle from the list it was loaded with', () async {
      when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
        (_) async => chopperListResponse([
          raffleFixture('r-1', 'Gala', null),
          raffleFixture('r-2', 'Loto', null),
        ]),
      );

      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(scaffold.repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(raffleListProvider.notifier);
      await notifier.loadRaffleList();

      final deleted = await notifier.deleteRaffle(
        raffleFixture('r-1', 'Gala', null),
      );

      expect(deleted, isTrue);
      expect(container.read(raffleListProvider).value!.map((r) => r.id), [
        'r-2',
      ]);
      // No network call: the raffle was already deleted server-side when the
      // list answered without it.
      verifyNever(
        () => scaffold.repository.tombolaRafflesRaffleIdDelete(
          raffleId: any(named: 'raffleId'),
        ),
      );
    });
  });

  group('drawPrize state arms', () {
    // `drawPrize` reads its own state through `when` AFTER awaiting the draw
    // call, and its loading/error arms answer a list that was still loading
    // or had failed at that instant. `build()` seeds the list from a microtask
    // and nothing ever assigns an error, so the arms are only reachable by
    // holding the state (see `HeldWinningTickets`); the draw itself is the
    // real one, so these run the production body.
    test(
      'a failing draw leaves the list untouched and answers an error',
      () async {
        when(
          () => scaffold.repository.tombolaPrizesPrizeIdDrawPost(
            prizeId: any(named: 'prizeId'),
          ),
        ).thenAnswer(
          (_) async =>
              chopperError<List<AppModulesRaffleSchemasRaffleTicketComplete>>(
                500,
              ),
        );

        final container = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(scaffold.repository),
            ticketsListProvider.overrideWith(() => FakeTicketsListNotifier([])),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(winningTicketListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        final result = await notifier.drawPrize(
          PrizeSimple.empty().copyWith(id: 'p-1'),
        );

        expect(
          result,
          isA<AsyncError<List<AppModulesRaffleSchemasRaffleTicketComplete>>>(),
        );
      },
    );

    /// The draw endpoint answering one ticket (the drawn list).
    void stubDraw() {
      when(
        () => scaffold.repository.tombolaPrizesPrizeIdDrawPost(
          prizeId: any(named: 'prizeId'),
        ),
      ).thenAnswer(
        (_) async => chopperListResponse([
          raffleTicketFixture(
            'drawn-1',
            'r-1',
            prize: PrizeSimple.empty().copyWith(id: 'p-1', name: 'PS5'),
          ),
        ]),
      );
    }

    test(
      'a draw landing on a loading list seeds it with the drawn tickets',
      () async {
        stubDraw();
        final container = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(scaffold.repository),
            winningTicketListProvider.overrideWith(
              () => HeldWinningTickets(const AsyncValue.loading()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(winningTicketListProvider.notifier);
        final result = await notifier.drawPrize(
          PrizeSimple.empty().copyWith(id: 'p-1'),
        );

        expect(
          result,
          isA<AsyncData<List<AppModulesRaffleSchemasRaffleTicketComplete>>>(),
        );
        // The loading arm replaces the pending list with the drawn tickets, so
        // the strip shows the winners even though the list never loaded.
        final state = container.read(winningTicketListProvider);
        expect(
          state,
          isA<AsyncData<List<AppModulesRaffleSchemasRaffleTicketComplete>>>(),
        );
        expect((state as AsyncData).value, hasLength(1));
        expect(state.value!.single.id, 'drawn-1');
      },
    );

    test(
      'a draw landing on a failed list answers it and keeps the failure',
      () async {
        stubDraw();
        final container = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(scaffold.repository),
            winningTicketListProvider.overrideWith(
              () => HeldWinningTickets(
                AsyncError('the list never loaded', StackTrace.current),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(winningTicketListProvider.notifier);
        final result = await notifier.drawPrize(
          PrizeSimple.empty().copyWith(id: 'p-1'),
        );

        // The caller still gets the drawn tickets (the winners dialog opens),
        // and the failed list is left as it was rather than half-rewritten.
        expect(
          result,
          isA<AsyncData<List<AppModulesRaffleSchemasRaffleTicketComplete>>>(),
        );
        expect(
          container.read(winningTicketListProvider),
          isA<AsyncError<List<AppModulesRaffleSchemasRaffleTicketComplete>>>(),
        );
      },
    );
  });
}
