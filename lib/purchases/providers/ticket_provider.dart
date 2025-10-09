import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/purchases/class/ticket.dart';
import 'package:titan/purchases/repositories/user_information_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class TicketNotifier extends SingleNotifier<Ticket> {
  final UserInformationRepository ticketRepository =
      UserInformationRepository();

  @override
  AsyncValue<Ticket> build() {
    final token = ref.watch(tokenProvider);
    ticketRepository.setToken(token);
    return const AsyncValue.loading();
  }

  void setTicket(Ticket i) {
    state = AsyncValue.data(i);
  }

  Future<AsyncValue<Ticket>> loadTicketSecret() async {
    state.whenData((ticket) async {
      return await load(() => ticketRepository.getTicketQrCodeSecret(ticket));
    });
    return state;
  }
}

final ticketProvider = NotifierProvider<TicketNotifier, AsyncValue<Ticket>>(
  TicketNotifier.new,
);
