import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/pack_ticket_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  group('PackTicketsListNotifier', () {
    test('loadPackTicketList resolves the raffle pack tickets', () async {
      when(() => repo.tombolaRafflesRaffleIdPackTicketsGet(raffleId: 'rf-1'))
          .thenAnswer((_) async => repo.okList<PackTicketSimple>());
      final notifier = container.read(packTicketListProvider.notifier);
      final state = await notifier.loadPackTicketList('rf-1');
      expect(state.value, isEmpty);
    });

    test('addPackTicket posts and appends the pack ticket', () async {
      final notifier = container.read(packTicketListProvider.notifier);
      final packTicket = PackTicketBase.empty().copyWith(
        price: 100,
        packSize: 5,
        raffleId: 'rf-1',
      );
      notifier.state = AsyncValue.data([]);
      when(
        () => repo.tombolaPackTicketsPost(body: any(named: 'body')),
      ).thenAnswer(
        (_) async =>
            repo.ok(PackTicketSimple.empty().copyWith(id: 'pk-1', price: 100)),
      );

      final ok = await notifier.addPackTicket(packTicket);
      expect(ok, isTrue);
      expect(notifier.state.value!.single.price, 100);
    });

    test('updatePackTicket success swaps the pack ticket', () async {
      final notifier = container.read(packTicketListProvider.notifier);
      final packTicket = PackTicketSimple.empty().copyWith(
        id: 'pk-1',
        price: 100,
        packSize: 5,
        raffleId: 'rf-1',
      );
      notifier.state = AsyncValue.data([packTicket]);
      when(
        () => repo.tombolaPackTicketsPackticketIdPatch(
          packticketId: 'pk-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.updatePackTicket(
        packTicket.copyWith(price: 250),
      );
      expect(ok, isTrue);
      expect(notifier.state.value!.single.price, 250);
    });

    test('updatePackTicket failure keeps the previous price', () async {
      final notifier = container.read(packTicketListProvider.notifier);
      final packTicket = PackTicketSimple.empty().copyWith(
        id: 'pk-1',
        price: 100,
        raffleId: 'rf-1',
      );
      notifier.state = AsyncValue.data([packTicket]);
      when(
        () => repo.tombolaPackTicketsPackticketIdPatch(
          packticketId: 'pk-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.fail<void>(400));

      final ok = await notifier.updatePackTicket(packTicket);
      expect(ok, isFalse);
      expect(notifier.state.value!.single.price, 100);
    });

    test('deletePackTicket success removes the pack ticket', () async {
      final notifier = container.read(packTicketListProvider.notifier);
      final packTicket = PackTicketSimple.empty().copyWith(id: 'pk-1');
      notifier.state = AsyncValue.data([packTicket]);
      when(
        () => repo.tombolaPackTicketsPackticketIdDelete(packticketId: 'pk-1'),
      ).thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deletePackTicket(packTicket);
      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });

    test('deletePackTicket failure keeps the pack ticket', () async {
      final notifier = container.read(packTicketListProvider.notifier);
      final packTicket = PackTicketSimple.empty().copyWith(id: 'pk-1');
      notifier.state = AsyncValue.data([packTicket]);
      when(
        () => repo.tombolaPackTicketsPackticketIdDelete(packticketId: 'pk-1'),
      ).thenAnswer((_) async => repo.fail<void>(404));

      final ok = await notifier.deletePackTicket(packTicket);
      expect(ok, isFalse);
      expect(notifier.state.value, hasLength(1));
    });
  });
}
