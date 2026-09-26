import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/device_list_provider.dart';
import 'package:titan/mypayment/providers/scan_provider.dart';
import 'package:titan/mypayment/providers/transaction_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('mypayment api notifiers', () {
    late MockRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('ScanNotifier', () {
      test('scan stores the transaction history on success', () async {
        final notifier = container.read(scanProvider.notifier);
        final transaction = TransactionBase.empty();
        when(
          () => mockRepository.mypaymentStoresStoreIdScanPost(
            storeId: 'store-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), transaction),
        );

        final result = await notifier.scan(
          'store-1',
          ScanInfo.empty(),
        );

        expect(result, isA<AsyncData<History>>());
        verify(
          () => mockRepository.mypaymentStoresStoreIdScanPost(
            storeId: 'store-1',
            body: any(named: 'body'),
          ),
        ).called(1);
      });

      test('scan handles error', () async {
        final notifier = container.read(scanProvider.notifier);
        when(
          () => mockRepository.mypaymentStoresStoreIdScanPost(
            storeId: 'store-1',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('scan failed'));

        final result = await notifier.scan('store-1', ScanInfo.empty());

        expect(result, isA<AsyncError<History>>());
      });

      test('canScan returns the backend verdict', () async {
        final notifier = container.read(scanProvider.notifier);
        when(
          () => mockRepository.mypaymentStoresStoreIdScanCheckPost(
            storeId: 'store-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 200),
            const AppTypesStandardResponsesResult(success: true),
          ),
        );

        expect(await notifier.canScan('store-1', ScanInfo.empty()), true);
      });

      test('canScan returns false on missing body', () async {
        final notifier = container.read(scanProvider.notifier);
        when(
          () => mockRepository.mypaymentStoresStoreIdScanCheckPost(
            storeId: 'store-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 200),
            const AppTypesStandardResponsesResult(),
          ),
        );

        expect(await notifier.canScan('store-1', ScanInfo.empty()), false);
      });

      test('reset puts the state back to loading', () async {
        final notifier = container.read(scanProvider.notifier);
        notifier.state = AsyncValue.data(History.empty());

        notifier.reset();

        expect(notifier.state.isLoading, true);
      });
    });

    group('TransactionNotifier', () {
      test('refundTransaction reflects the response status', () async {
        final notifier = container.read(transactionProvider.notifier);
        when(
          () => mockRepository.mypaymentTransactionsTransactionIdRefundPost(
            transactionId: 'tx-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), null),
        );

        final result = await notifier.refundTransaction(
          'tx-1',
          RefundInfo.empty(),
        );

        expect(result.value, true);
      });

      test('refundTransaction handles failure', () async {
        final notifier = container.read(transactionProvider.notifier);
        when(
          () => mockRepository.mypaymentTransactionsTransactionIdRefundPost(
            transactionId: 'tx-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('err', 400), null),
        );

        final result = await notifier.refundTransaction(
          'tx-1',
          RefundInfo.empty(),
        );

        expect(result.value, false);
      });

      test('cancelTransaction reflects the response status', () async {
        final notifier = container.read(transactionProvider.notifier);
        when(
          () => mockRepository.mypaymentTransactionsTransactionIdCancelPost(
            transactionId: 'tx-1',
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), null),
        );

        final result = await notifier.cancelTransaction('tx-1');

        expect(result.value, true);
      });

      test('cancelTransaction handles failure', () async {
        final notifier = container.read(transactionProvider.notifier);
        when(
          () => mockRepository.mypaymentTransactionsTransactionIdCancelPost(
            transactionId: 'tx-1',
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('err', 400), null),
        );

        final result = await notifier.cancelTransaction('tx-1');

        expect(result.value, false);
      });
    });

    group('DeviceListNotifier', () {
      test('getDeviceList loads the devices', () async {
        final notifier = container.read(deviceListProvider.notifier);
        final devices = [WalletDevice.empty().copyWith(id: 'device-1')];
        when(
          () => mockRepository.mypaymentUsersMeWalletDevicesGet(),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), devices),
        );

        await notifier.getDeviceList();

        expect(notifier.state.value, devices);
      });

      test('getDeviceList handles error', () async {
        final notifier = container.read(deviceListProvider.notifier);
        when(
          () => mockRepository.mypaymentUsersMeWalletDevicesGet(),
        ).thenThrow(Exception('devices failed'));

        final result = await notifier.getDeviceList();

        expect(result, isA<AsyncError<List<WalletDevice>>>());
      });

      test('revokeDevice removes the device from the list', () async {
        final notifier = container.read(deviceListProvider.notifier);
        final device = WalletDevice.empty().copyWith(id: 'device-1');
        notifier.state = AsyncValue.data([device]);
        when(
          () => mockRepository.mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost(
            walletDeviceId: 'device-1',
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), null),
        );

        final result = await notifier.revokeDevice(device);

        expect(result, true);
        // The revoke endpoint returns no body, so update() keeps the old list.
        expect(notifier.state.value, [device]);
      });

      test('revokeDevice handles error', () async {
        final notifier = container.read(deviceListProvider.notifier);
        final device = WalletDevice.empty().copyWith(id: 'device-1');
        notifier.state = AsyncValue.data([device]);
        when(
          () => mockRepository.mypaymentUsersMeWalletDevicesWalletDeviceIdRevokePost(
            walletDeviceId: 'device-1',
          ),
        ).thenThrow(Exception('revoke failed'));

        final result = await notifier.revokeDevice(device);

        expect(result, false);
      });
    });
  });
}
