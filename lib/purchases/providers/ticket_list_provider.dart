import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/purchases/class/ticket.dart';
import 'package:titan/purchases/repositories/scanner_repository.dart';
import 'package:titan/purchases/repositories/user_information_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class TicketListNotifier extends ListNotifier<Ticket> {
  UserInformationRepository get ticketRepository =>
      ref.watch(userInformationRepositoryProvider);
  ScannerRepository get scannerRepository =>
      ref.watch(scannerRepositoryProvider);

  @override
  AsyncValue<List<Ticket>> build() {
    tokenExpireWrapperAuth(ref, () async {
      await loadTickets();
    });

    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Ticket>>> loadTickets() async {
    return await loadList(ticketRepository.getTicketList);
  }

  Future<bool> consumeTicket(
    String sellerId,
    Ticket ticket,
    String generatorId,
    String tag,
  ) async {
    return await update(
      (Ticket fakeTicket) =>
          scannerRepository.consumeTicket(sellerId, ticket, generatorId, tag),
      (tickets, ticket) {
        List<String> tags = ticket.tags;
        tags.add(tag);
        return tickets
          ..[tickets.indexWhere((g) => g.id == ticket.id)] = ticket.copyWith(
            tags: tags,
            scanLeft: ticket.scanLeft - 1,
          );
      },
      ticket,
    );
  }
}

final ticketListProvider =
    NotifierProvider<TicketListNotifier, AsyncValue<List<Ticket>>>(
      TicketListNotifier.new,
    );
