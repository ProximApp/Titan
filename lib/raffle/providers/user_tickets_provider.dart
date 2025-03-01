import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class UserTicketListNotifier extends ListNotifierAPI<TicketComplete> {
  Openapi get userTicketsRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<TicketComplete>> build() {
    tokenExpireWrapperAuth(ref, () async {
      final userIdAsync = ref.watch(idProvider);
      userIdAsync.whenData((value) async {
        await loadTicketList(value);
      });
    });

    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<TicketComplete>>> loadTicketList(String userId) async {
    return await loadList(
      () => userTicketsRepository.tombolaUsersUserIdTicketsGet(userId: userId),
    );
  }

  Future<bool> buyTicket(PackTicketSimple packTicket) async {
    return addAll(
      (_) async => userTicketsRepository.tombolaTicketsBuyPackIdPost(
        packId: packTicket.id,
      ),
      [],
    );
  }
}

final userTicketListProvider =
    NotifierProvider<UserTicketListNotifier, AsyncValue<List<TicketComplete>>>(
      UserTicketListNotifier.new,
    );
