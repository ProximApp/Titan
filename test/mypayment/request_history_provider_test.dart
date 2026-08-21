import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/request_history_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRequestHistoryRepository extends Mock implements Openapi {}

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
  group('RequestHistoryNotifier', () {
    late MockRequestHistoryRepository mockRepository;
    late ProviderContainer container;
    late RequestHistoryNotifier notifier;

    setUp(() {
      mockRepository = MockRequestHistoryRepository();
      when(
        () => mockRepository.mypaymentRequestsGet(used: any(named: 'used')),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('[]', 200), <Request$>[]),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(requestHistoryProvider.notifier);
    });

    tearDown(() => container.dispose());

    test(
      'getRequestHistory should request used requests from the repository',
      () async {
        final requests = [request(status: RequestStatus.accepted)];
        when(
          () => mockRepository.mypaymentRequestsGet(used: any(named: 'used')),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('[]', 200), requests),
        );
        final result = await notifier.getRequestHistory();
        expect(result, isA<AsyncData<List<Request$>>>());
        expect(
          result.when(
            data: (data) => data.length,
            loading: () => 0,
            error: (error, stackTrace) => 0,
          ),
          1,
        );
        // build() already triggered one load on notifier creation.
        verify(() => mockRepository.mypaymentRequestsGet(used: true)).called(2);
      },
    );

    test('getRequestHistory should handle error', () async {
      when(
        () => mockRepository.mypaymentRequestsGet(used: any(named: 'used')),
      ).thenThrow(Exception('Error'));
      final result = await notifier.getRequestHistory();
      expect(result, isA<AsyncError>());
    });
  });
}
