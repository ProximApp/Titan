import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class RequestHistoryNotifier extends ListNotifierAPI<Request$> {
  Openapi get requestsRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<Request$>> build() {
    getRequestHistory();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Request$>>> getRequestHistory() async {
    return await loadList(
      () => requestsRepository.mypaymentRequestsGet(used: true),
    );
  }
}

final requestHistoryProvider =
    NotifierProvider<RequestHistoryNotifier, AsyncValue<List<Request$>>>(
      RequestHistoryNotifier.new,
    );
