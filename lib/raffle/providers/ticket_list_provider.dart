import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/raffle/class/raffle.dart';
import 'package:titan/raffle/class/tickets.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/repositories/raffle_detail_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class TicketsListNotifier extends ListNotifier<Ticket> {
  final RaffleDetailRepository _raffleDetailRepository =
      RaffleDetailRepository();
  late String raffleId;

  @override
  AsyncValue<List<Ticket>> build() {
    final token = ref.watch(tokenProvider);
    _raffleDetailRepository.setToken(token);
    final currentRaffleId = ref.watch(raffleIdProvider);
    if (currentRaffleId != Raffle.empty().id) {
      setId(currentRaffleId);
      loadTicketList();
    }
    return const AsyncValue.loading();
  }

  void setId(String id) {
    raffleId = id;
  }

  Future<AsyncValue<List<Ticket>>> loadTicketList() async {
    return await loadList(
      () async => _raffleDetailRepository.getTicketListFromRaffle(raffleId),
    );
  }
}

final ticketsListProvider =
    NotifierProvider<TicketsListNotifier, AsyncValue<List<Ticket>>>(
      TicketsListNotifier.new,
    );
