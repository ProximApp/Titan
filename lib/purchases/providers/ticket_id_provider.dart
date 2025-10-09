import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/purchases/repositories/user_information_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class TicketIdNotifier extends SingleNotifier<String> {
  UserInformationRepository get ticketIdRepository =>
      ref.watch(userInformationRepositoryProvider);

  @override
  AsyncValue<String> build() {
    return const AsyncValue.loading();
  }

  void setTicketId(String i) {
    state = AsyncValue.data(i);
  }
}

final ticketIdProvider = NotifierProvider<TicketIdNotifier, AsyncValue<String>>(
  TicketIdNotifier.new,
);
