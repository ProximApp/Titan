import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/auth/providers/is_connected_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('IsConnectedProvider', () {
    late MockRepository mockRepository;
    late ProviderContainer container;

    final information = CoreInformation(
      ready: true,
      version: '1.0.0',
      minimalTitanVersionCode: 1,
    );

    // Connectivity is now read off the `/information` call that
    // `versionVerifierProvider` already makes, rather than a second request of
    // its own, so the repository has to be stubbed the same way that provider's
    // own test stubs it.
    setUp(() {
      mockRepository = MockRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('is false until the first answer comes back', () {
      when(() => mockRepository.informationGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), information),
      );

      // Read synchronously: the request is in flight and nothing has resolved,
      // which is the state the app shows its offline screen for.
      expect(container.read(isConnectedProvider), false);
    });

    test('is true once the backend answers', () async {
      when(() => mockRepository.informationGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), information),
      );

      container.read(isConnectedProvider);
      await container.read(isConnectedProvider.notifier).isInternet();

      expect(container.read(isConnectedProvider), true);
    });

    test('stays false when the backend cannot be reached', () async {
      when(
        () => mockRepository.informationGet(),
      ).thenThrow(Exception('No route to host'));

      container.read(isConnectedProvider);
      await container.read(isConnectedProvider.notifier).isInternet();

      expect(container.read(isConnectedProvider), false);
    });

    test('recovers when a retry succeeds', () async {
      when(
        () => mockRepository.informationGet(),
      ).thenThrow(Exception('No route to host'));

      container.read(isConnectedProvider);
      await container.read(isConnectedProvider.notifier).isInternet();
      expect(container.read(isConnectedProvider), false);

      // This is what the retry button on the no-internet page does.
      when(() => mockRepository.informationGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), information),
      );
      await container.read(isConnectedProvider.notifier).isInternet();

      expect(container.read(isConnectedProvider), true);
    });
  });
}
