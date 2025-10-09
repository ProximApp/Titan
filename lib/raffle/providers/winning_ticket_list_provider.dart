import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/prize.dart';
import 'package:titan/raffle/class/tickets.dart';
import 'package:titan/raffle/providers/ticket_list_provider.dart';
import 'package:titan/raffle/repositories/prize_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class WinningTicketNotifier extends ListNotifier<Ticket> {
  LotRepository get lotRepository => ref.watch(lotRepositoryProvider);

  @override
  AsyncValue<List<Ticket>> build() {
    final ticketFromRaffle = ref.watch(ticketsListProvider);
    final winningTickets = ticketFromRaffle.maybeWhen<List<Ticket>>(
      data: (data) => data.where((element) => element.prize != null).toList(),
      orElse: () => [],
    );

    Future.microtask(() => setData(winningTickets));
    return const AsyncValue.loading();
  }

  void setData(List<Ticket> tickets) {
    state = AsyncValue.data(tickets);
  }

  Future<AsyncValue<List<Ticket>>> drawPrize(Prize lot) async {
    final drawnList = await lotRepository.drawLot(lot);
    state.when(
      data: (list) {
        state = AsyncValue.data(list + drawnList);
      },
      error: (e, s) {},
      loading: () {
        state = AsyncValue.data(drawnList);
      },
    );
    return AsyncData(drawnList);
  }
}

final winningTicketListProvider =
    NotifierProvider<WinningTicketNotifier, AsyncValue<List<Ticket>>>(
      WinningTicketNotifier.new,
    );
