import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class PaymentRequestsNotifier extends ListNotifierAPI<Request$> {
  Openapi get requestsRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<Request$>> build() {
    getRequests();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Request$>>> getRequests() async {
    return await loadList(() => requestsRepository.mypaymentRequestsGet());
  }

  Future<bool> acceptRequest(Request$ request, SignedContent validation) async {
    return await update(
      () => requestsRepository.mypaymentRequestsRequestIdAcceptPost(
        requestId: request.id,
        body: validation,
      ),
      (r) => r.id,
      request.copyWith(status: RequestStatus.accepted),
    );
  }

  Future<bool> refuseRequest(Request$ request) async {
    return await update(
      () => requestsRepository.mypaymentRequestsRequestIdRefusePost(
        requestId: request.id,
      ),
      (r) => r.id,
      request.copyWith(status: RequestStatus.refused),
    );
  }
}

final paymentRequestsProvider =
    NotifierProvider<PaymentRequestsNotifier, AsyncValue<List<Request$>>>(
      PaymentRequestsNotifier.new,
    );
