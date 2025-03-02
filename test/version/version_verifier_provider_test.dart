import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/version/class/version.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';
import 'package:titan/version/repositories/version_repository.dart';

class MockVersionRepository extends Mock implements Openapi {}

void main() {
  group('VersionVerifierNotifier', () {
    late MockVersionRepository mockRepository;
    late VersionVerifierNotifier provider;
    final version = CoreInformation(
      ready: true,
      version: '1.0.0',
      minimalTitanVersionCode: 1,
    );

    setUp(() {
      mockRepository = MockVersionRepository();
      provider = VersionVerifierNotifier(versionRepository: mockRepository);
    });

    test('loadVersion returns expected data', () async {
      when(() => mockRepository.informationGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          version,
        ),
      );

        final result = await provider.loadVersion();

      expect(
        result.maybeWhen(
          data: (data) => data,
          orElse: () => null,
        ),
        version,
      );
    });

    test('loadVersion handles error', () async {
      when(() => mockRepository.informationGet())
          .thenThrow(Exception('Failed to load version'));

      final result = await provider.loadVersion();

      expect(
        result.maybeWhen(
          error: (error, _) => error,
          orElse: () => null,
        ),
        isA<Exception>(),
      );
    });
  });
}
