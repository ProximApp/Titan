import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/purchases/repositories/user_information_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class TicketIdNotifier extends SingleNotifier<String> {
  final UserInformationRepository ticketIdRepository =
      UserInformationRepository();

  @override
  AsyncValue<String> build() {
    final token = ref.watch(tokenProvider);
    ticketIdRepository.setToken(token);
    return const AsyncValue.loading();
  }

  void setTicketId(String i) {
    state = AsyncValue.data(i);
  }
}

final ticketIdProvider = NotifierProvider<TicketIdNotifier, AsyncValue<String>>(
  TicketIdNotifier.new,
);
