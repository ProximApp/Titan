import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/can_pay_provider.dart';
import 'package:titan/mypayment/providers/has_accepted_tos_provider.dart';
import 'package:titan/mypayment/providers/key_service_provider.dart';
import 'package:titan/mypayment/tools/can_pay.dart';
import 'package:titan/mypayment/tools/key_service.dart';
import 'package:titan/tools/repository/repository.dart';

class MockKeyService extends Mock implements KeyService {}

class MockRepository extends Mock implements Openapi {}

/// Stands in for the real [HasAcceptedTosNotifier], whose build() fetches the
/// TOS signature from the repository.
class FakeHasAcceptedTosNotifier extends HasAcceptedTosNotifier {
  FakeHasAcceptedTosNotifier(this.accepted);

  final bool accepted;

  @override
  bool build() => accepted;
}

WalletDevice _device(WalletDeviceStatus status) =>
    WalletDevice.empty().copyWith(id: 'device-1', status: status);

void main() {
  group('canPayProvider', () {
    late MockKeyService keyService;
    late MockRepository repository;
    late ProviderContainer container;

    setUp(() {
      keyService = MockKeyService();
      repository = MockRepository();
      container = ProviderContainer(
        overrides: [
          hasAcceptedTosProvider.overrideWith(
            () => FakeHasAcceptedTosNotifier(true),
          ),
          keyServiceProvider.overrideWithValue(keyService),
          repositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('fails when the TOS is not accepted', () async {
      final tosContainer = ProviderContainer(
        overrides: [
          hasAcceptedTosProvider.overrideWith(
            () => FakeHasAcceptedTosNotifier(false),
          ),
          keyServiceProvider.overrideWithValue(keyService),
          repositoryProvider.overrideWithValue(repository),
        ],
      );

      final result = await tosContainer.read(canPayProvider.future);

      expect(result.success, false);
      expect(result.error, CanPayError.tosNotAccepted);
      tosContainer.dispose();
    });

    test('fails when no device is registered on this install', () async {
      when(() => keyService.getKeyId()).thenAnswer((_) async => null);

      final result = await container.read(canPayProvider.future);

      expect(result.success, false);
      expect(result.error, CanPayError.noDevice);
      verifyNever(
        () => repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
          walletDeviceId: any(named: 'walletDeviceId'),
        ),
      );
    });

    test('fails when the backend does not know the device', () async {
      when(() => keyService.getKeyId()).thenAnswer((_) async => 'device-1');
      when(
        () => repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
          walletDeviceId: 'device-1',
        ),
      ).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('{}', 404), null),
      );

      final result = await container.read(canPayProvider.future);

      expect(result.success, false);
      expect(result.error, CanPayError.noDevice);
    });

    test('fails when the device is inactive', () async {
      when(() => keyService.getKeyId()).thenAnswer((_) async => 'device-1');
      when(
        () => repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
          walletDeviceId: 'device-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          _device(WalletDeviceStatus.inactive),
        ),
      );

      final result = await container.read(canPayProvider.future);

      expect(result.success, false);
      expect(result.error, CanPayError.deviceInactive);
    });

    test('fails when the device is revoked', () async {
      when(() => keyService.getKeyId()).thenAnswer((_) async => 'device-1');
      when(
        () => repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
          walletDeviceId: 'device-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          _device(WalletDeviceStatus.revoked),
        ),
      );

      final result = await container.read(canPayProvider.future);

      expect(result.success, false);
      expect(result.error, CanPayError.deviceRevoked);
    });

    test('succeeds when the device is active and TOS accepted', () async {
      when(() => keyService.getKeyId()).thenAnswer((_) async => 'device-1');
      when(
        () => repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
          walletDeviceId: 'device-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          _device(WalletDeviceStatus.active),
        ),
      );

      final result = await container.read(canPayProvider.future);

      expect(result.success, true);
      expect(result.error, null);
    });
  });
}
