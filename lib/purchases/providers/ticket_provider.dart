import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/tools/repository/repository.dart';

class TicketNotifier extends SingleNotifier<Ticket> {
  Openapi get ticketRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<Ticket> build() {
    return const AsyncValue.loading();
  }

  void setTicket(Ticket i) {
    state = AsyncValue.data(i);
  }

  Future<AsyncValue<TicketSecret>> loadTicketSecret() async {
    return state.maybeWhen(
      orElse: () async {
        return AsyncValue.error('Ticket is not loaded', StackTrace.current);
      },
      data: (value) async {
        final response = await ticketRepository
            .cdrUsersMeTicketsTicketIdSecretGet(ticketId: value.id);
        if (response.isSuccessful) {
          return AsyncValue.data(response.body!);
        }
        return AsyncValue.error(response.error.toString(), StackTrace.current);
      },
    );
  }
}

final ticketProvider = NotifierProvider<TicketNotifier, AsyncValue<Ticket>>(
  TicketNotifier.new,
);
