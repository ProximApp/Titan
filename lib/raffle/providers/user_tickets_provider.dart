import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/raffle/class/pack_ticket.dart';
import 'package:titan/raffle/class/tickets.dart';
import 'package:titan/raffle/repositories/tickets_repository.dart';
import 'package:titan/raffle/repositories/user_tickets_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class UserTicketListNotifier extends ListNotifier<Ticket> {
  final UserDetailRepository _userDetailRepository = UserDetailRepository();
  final TicketRepository _ticketsRepository = TicketRepository();
  late String userId;

  @override
  AsyncValue<List<Ticket>> build() {
    final token = ref.watch(tokenProvider);
    _userDetailRepository.setToken(token);
    _ticketsRepository.setToken(token);

    tokenExpireWrapperAuth(ref, () async {
      final userIdAsync = ref.watch(idProvider);
      userIdAsync.whenData((value) async {
        setId(value);
        await loadTicketList();
      });
    });

    return const AsyncValue.loading();
  }

  void setId(String id) {
    userId = id;
  }

  Future<AsyncValue<List<Ticket>>> loadTicketList() async {
    return await loadList(
      () async => _userDetailRepository.getTicketsListByUserId(userId),
    );
  }

  Future<bool> buyTicket(PackTicket packTicket) async {
    return addAll(
      (_) async => _ticketsRepository.buyTicket(packTicket.id, userId),
      [],
    );
  }
}

final userTicketListProvider =
    NotifierProvider<UserTicketListNotifier, AsyncValue<List<Ticket>>>(
      UserTicketListNotifier.new,
    );
