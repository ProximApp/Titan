import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/tools/builders/empty_models.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class TicketsListNotifier extends ListNotifierAPI<TicketComplete> {
  Openapi get raffleDetailRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<TicketComplete>> build() {
    final currentRaffleId = ref.watch(raffleIdProvider);
    if (currentRaffleId != EmptyModels.empty<RaffleComplete>().id) {
      loadTicketList(currentRaffleId);
    }
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<TicketComplete>>> loadTicketList(
    String raffleId,
  ) async {
    return await loadList(
      () async => raffleDetailRepository.tombolaRafflesRaffleIdTicketsGet(
        raffleId: raffleId,
      ),
    );
  }
}

final ticketsListProvider =
    NotifierProvider<TicketsListNotifier, AsyncValue<List<TicketComplete>>>(
      TicketsListNotifier.new,
    );
