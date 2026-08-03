import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/payment_requests_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockPaymentRequestsRepository extends Mock implements Openapi {}

Request$ request({
  String id = '1',
  RequestStatus status = RequestStatus.proposed,
}) {
  return Request$(
    id: id,
    walletId: 'wallet-1',
    creation: DateTime(2026, 4, 22, 10, 1),
    expirationDate: DateTime.now().add(const Duration(minutes: 15)),
    total: 100,
    storeId: 'store-1',
    name: 'Commuz',
    storeNote: null,
    module: 'mypayment',
    objectId: 'obj-1',
    status: status,
    transactionId: null,
  );
}

void main() {
  group('PaymentRequestsNotifier', () {
    late MockPaymentRequestsRepository mockRepository;
    late ProviderContainer container;
    late PaymentRequestsNotifier notifier;

    setUp(() {
      mockRepository = MockPaymentRequestsRepository();
      when(() => mockRepository.mypaymentRequestsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('[]', 200), <Request$>[]),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(paymentRequestsProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('getRequests should load the list from the repository', () async {
      final requests = [request()];
      when(() => mockRepository.mypaymentRequestsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('[]', 200), requests),
      );
      final result = await notifier.getRequests();
      expect(result, isA<AsyncData<List<Request$>>>());
      expect(
        result.when(
          data: (data) => data.length,
          loading: () => 0,
          error: (error, stackTrace) => 0,
        ),
        1,
      );
    });

    test('getRequests should handle error', () async {
      when(
        () => mockRepository.mypaymentRequestsGet(),
      ).thenThrow(Exception('Error'));
      final result = await notifier.getRequests();
      expect(result, isA<AsyncError>());
    });

    test(
      'acceptRequest should update the request status to accepted',
      () async {
        final proposed = request(status: RequestStatus.proposed);
        final validation = SignedContent(
          id: proposed.id,
          tot: proposed.total,
          iat: DateTime.now(),
          key: 'key-1',
          store: true,
          signature: 'sig',
        );
        notifier.state = AsyncValue.data([proposed]);
        when(
          () => mockRepository.mypaymentRequestsRequestIdAcceptPost(
            requestId: any(named: 'requestId'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('', 200), null),
        );
        final result = await notifier.acceptRequest(proposed, validation);
        expect(result, true);
        expect(
          notifier.state,
          isA<AsyncData<List<Request$>>>().having(
            (data) => data.value.single.status,
            'status',
            RequestStatus.accepted,
          ),
        );
      },
    );

    test('acceptRequest should handle error', () async {
      final proposed = request(status: RequestStatus.proposed);
      final validation = SignedContent(
        id: proposed.id,
        tot: proposed.total,
        iat: DateTime.now(),
        key: 'key-1',
        store: true,
        signature: 'sig',
      );
      notifier.state = AsyncValue.data([proposed]);
      when(
        () => mockRepository.mypaymentRequestsRequestIdAcceptPost(
          requestId: any(named: 'requestId'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('Error'));
      final result = await notifier.acceptRequest(proposed, validation);
      expect(result, false);
    });

    test('refuseRequest should update the request status to refused', () async {
      final proposed = request(status: RequestStatus.proposed);
      notifier.state = AsyncValue.data([proposed]);
      when(
        () => mockRepository.mypaymentRequestsRequestIdRefusePost(
          requestId: any(named: 'requestId'),
        ),
      ).thenAnswer((_) async => chopper.Response(http.Response('', 200), null));
      final result = await notifier.refuseRequest(proposed);
      expect(result, true);
      expect(
        notifier.state,
        isA<AsyncData<List<Request$>>>().having(
          (data) => data.value.single.status,
          'status',
          RequestStatus.refused,
        ),
      );
    });

    test('refuseRequest should handle error', () async {
      final proposed = request(status: RequestStatus.proposed);
      notifier.state = AsyncValue.data([proposed]);
      when(
        () => mockRepository.mypaymentRequestsRequestIdRefusePost(
          requestId: any(named: 'requestId'),
        ),
      ).thenThrow(Exception('Error'));
      final result = await notifier.refuseRequest(proposed);
      expect(result, false);
    });
  });
}
