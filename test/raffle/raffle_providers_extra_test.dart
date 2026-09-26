import 'dart:io';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/is_raffle_admin.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/providers/raffle_list_provider.dart';
import 'package:titan/raffle/providers/ticket_list_provider.dart';
import 'package:titan/raffle/providers/winning_ticket_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';

class MockRepository extends Mock implements Openapi {}

class FakeTicketsListNotifier extends TicketsListNotifier {
  FakeTicketsListNotifier(this.tickets);
  final List<AppModulesRaffleSchemasRaffleTicketComplete> tickets;

  @override
  AsyncValue<List<AppModulesRaffleSchemasRaffleTicketComplete>> build() =>
      AsyncValue.data(tickets);
}

class FakeRaffleIdNotifier extends RaffleIdProvider {
  FakeRaffleIdNotifier(this.id);
  final String id;

  @override
  String build() => id;
}

class _LoadingRaffleListNotifier extends RaffleListNotifier {
  @override
  AsyncValue<List<RaffleComplete>> build() => const AsyncValue.loading();
}

AppModulesRaffleSchemasRaffleTicketComplete ticket(String id, {PrizeSimple? prize}) =>
    AppModulesRaffleSchemasRaffleTicketComplete.empty().copyWith(id: id, prize: prize);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockRepository mockRepository;

  setUpAll(() async {
    // Repositories log through a static Logger whose FileLoggerOutput writes
    // to <documents>/myecl.log. Point path_provider at a real temp directory.
    await Directory.systemTemp.createTemp('titan_test_documents').then((dir) {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'getApplicationDocumentsDirectory':
              case 'getTemporaryDirectory':
                return dir.path;
            }
            return null;
          });
    });
  });

  setUp(() {
    mockRepository = MockRepository();
  });

  group('WinningTicketNotifier', () {
    setUp(() {
      mockRepository = MockRepository();
    });

    test('lists only the tickets that have a prize', () async {
      final winningPrize = PrizeSimple.empty().copyWith(id: 'prize-1');
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          ticketsListProvider.overrideWith(
            () => FakeTicketsListNotifier([
              ticket('t-1', prize: winningPrize),
              ticket('t-2'),
              ticket('t-3', prize: PrizeSimple.empty().copyWith(id: 'prize-2')),
            ]),
          ),
        ],
      );

      final notifier = container.read(winningTicketListProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final state = container.read(winningTicketListProvider);

      expect(state.value, hasLength(2));
      expect(notifier, isNotNull);

      container.dispose();
    });

    test('keeps an empty list while no ticket has a prize', () async {
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          ticketsListProvider.overrideWith(
            () => FakeTicketsListNotifier([ticket('t-1')]),
          ),
        ],
      );

      container.read(winningTicketListProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(winningTicketListProvider).value, isEmpty);

      container.dispose();
    });

    test('drawPrize appends the drawn tickets', () async {
      final drawn = [
        AppModulesRaffleSchemasRaffleTicketComplete.empty().copyWith(id: 't-drawn'),
      ];
      when(
        () => mockRepository.tombolaPrizesPrizeIdDrawPost(
          prizeId: any(named: 'prizeId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), drawn),
      );

      final winning = ticket('t-1', prize: PrizeSimple.empty().copyWith(id: 'p-1'));
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          ticketsListProvider.overrideWith(
            () => FakeTicketsListNotifier([winning]),
          ),
        ],
      );

      final notifier = container.read(winningTicketListProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final result = await notifier.drawPrize(
        PrizeSimple.empty().copyWith(id: 'p-1'),
      );

      expect(result.value, drawn);
      expect(container.read(winningTicketListProvider).value, [winning, ...drawn]);

      container.dispose();
    });

    test('drawPrize returns an error when the call fails', () async {
      when(
        () => mockRepository.tombolaPrizesPrizeIdDrawPost(
          prizeId: any(named: 'prizeId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('error', 400),
          null,
          error: 'cannot draw',
        ),
      );

      final winning = ticket('t-1', prize: PrizeSimple.empty().copyWith(id: 'p-1'));
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          ticketsListProvider.overrideWith(
            () => FakeTicketsListNotifier([winning]),
          ),
        ],
      );

      final notifier = container.read(winningTicketListProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final result = await notifier.drawPrize(
        PrizeSimple.empty().copyWith(id: 'p-1'),
      );

      expect(result, isA<AsyncError<List<AppModulesRaffleSchemasRaffleTicketComplete>>>());
      expect(container.read(winningTicketListProvider).value, [winning]);

      container.dispose();
    });
  });

  group('RaffleIdProvider', () {
    test('starts with an empty id while the raffles are not loaded and can be set', () {
      final container = ProviderContainer(
        overrides: [
          raffleListProvider.overrideWith(_LoadingRaffleListNotifier.new),
        ],
      );

      expect(container.read(raffleIdProvider), '');

      final notifier = container.read(raffleIdProvider.notifier);
      notifier.setId('raffle-42');
      expect(container.read(raffleIdProvider), 'raffle-42');

      container.dispose();
    });

    test('FakeRaffleIdNotifier overrides the derived id', () {
      final container = ProviderContainer(
        overrides: [raffleIdProvider.overrideWith(() => FakeRaffleIdNotifier('x'))],
      );

      expect(container.read(raffleIdProvider), 'x');

      container.dispose();
    });
  });

  group('isRaffleAdminProvider', () {
    test('is true when the user is in the raffle admin group', () {
      final user = CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(user)],
      );

      expect(container.read(isRaffleAdminProvider), isTrue);

      container.dispose();
    });

    test('is false for a regular user', () {
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(CoreUser.empty())],
      );

      expect(container.read(isRaffleAdminProvider), isFalse);

      container.dispose();
    });
  });
}
