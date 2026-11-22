import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/device_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// `DeviceNotifier.registerDevice`'s three outcomes.
///
/// The devices page's own tests drive the happy path through the real POST;
/// the two error arms — a 200 with no device body, and a throwing POST — were
/// never reached, so nothing proved the page's error toast could fire at all.
void main() {
  group('DeviceNotifier.registerDevice', () {
    late MockOpenapi mockRepository;
    late ProviderContainer container;
    late DeviceNotifier notifier;

    final phone = WalletDevice.empty().copyWith(id: 'device-1', name: 'Phone');
    final creation = WalletDeviceCreation.empty();

    setUp(() {
      mockRepository = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(deviceProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('a created device becomes the state and answers its id', () async {
      when(
        () => mockRepository.mypaymentUsersMeWalletDevicesPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopper.Response(http.Response('body', 200), phone));

      final id = await notifier.registerDevice(creation);

      expect(id, 'device-1');
      expect(container.read(deviceProvider).value?.id, 'device-1');
    });

    test('an empty answer leaves an error state and no id', () async {
      when(
        () => mockRepository.mypaymentUsersMeWalletDevicesPost(
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      final id = await notifier.registerDevice(creation);

      expect(id, isNull);
      expect(
        container.read(deviceProvider).error,
        'Error while creating device',
      );
    });

    test('a throwing POST leaves an error state and no id', () async {
      when(
        () => mockRepository.mypaymentUsersMeWalletDevicesPost(
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('device refused'));

      final id = await notifier.registerDevice(creation);

      expect(id, isNull);
      expect(container.read(deviceProvider).hasError, isTrue);
    });
  });
}
