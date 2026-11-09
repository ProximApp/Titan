import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/auth/providers/is_connected_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/auth/repository/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Truthful stand-in: the session-derivation logic only branches on this
/// boolean; the real one pulls the version verifier and the whole network
/// stack, which is app bootstrap, not auth state.
class _StaticIsConnected extends IsConnectedProvider {
  _StaticIsConnected(this.value);
  final bool value;

  @override
  bool build() => value;
}

/// Builds a real JWT with the given `exp` so the actual JwtDecoder decides
/// validity — no fake decoding anywhere.
String jwtWithExpiry(DateTime expiry) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'RS256', 'typ': 'JWT'})}.'
      '${part({'sub': 'user-42', 'exp': expiry.millisecondsSinceEpoch ~/ 1000})}.sig';
}

class FakeOpenIdToken extends OpenIdTokenProvider {
  FakeOpenIdToken(this.token);
  final models.TokenResponse token;

  @override
  AsyncValue<models.TokenResponse> build() => AsyncValue.data(token);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  ProviderContainer containerWithToken(models.TokenResponse token) {
    final container = ProviderContainer(
      overrides: [
        // The session-derivation chain only: no version verifier, no network
        // chain — this file tests auth state, not app bootstrap.
        isConnectedProvider.overrideWith(() => _StaticIsConnected(true)),
        authTokenProvider.overrideWith(() => FakeOpenIdToken(token)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('session validity derived from the access token expiry', () {
    test('a non-expired access token means signed in', () {
      final container = containerWithToken(
        models.TokenResponse(
          accessToken: jwtWithExpiry(
            DateTime.now().add(const Duration(hours: 1)),
          ),
          refreshToken: 'r',
        ),
      );

      expect(container.read(isLoggedInProvider), isTrue);
    });

    test('an expired access token means signed out', () {
      final container = containerWithToken(
        models.TokenResponse(
          accessToken: jwtWithExpiry(
            DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          refreshToken: 'r',
        ),
      );

      expect(container.read(isLoggedInProvider), isFalse);
    });

    test('an unparseable token means signed out (no crash)', () {
      final container = containerWithToken(
        const models.TokenResponse(accessToken: 'garbage', refreshToken: 'r'),
      );

      expect(container.read(isLoggedInProvider), isFalse);
    });

    test('loadingProvider exposes the error state while signed out', () {
      final container = containerWithToken(
        const models.TokenResponse(accessToken: 'garbage', refreshToken: 'r'),
      );

      // The login page drives its spinner off this provider; a dead session
      // must not read as "loading" forever.
      expect(container.read(loadingProvider).value, isFalse);
    });
  });

  group('OpenIdTokenProvider.refreshAccessToken (provider side)', () {
    test(
      'stores the refreshed token and returns the new access token',
      () async {
        final authRepository = MockAuthRepository();
        final jwt = jwtWithExpiry(DateTime.now().add(const Duration(hours: 1)));
        when(() => authRepository.refreshToken()).thenAnswer(
          (_) async => models.TokenResponse(
            accessToken: jwt,
            refreshToken: 'rotated-refresh',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            isConnectedProvider.overrideWith(() => _StaticIsConnected(true)),
            authRepositoryProvider.overrideWithValue(authRepository),
            // Start from a dead session (the state the refresh heals).
            authTokenProvider.overrideWith(
              () => FakeOpenIdToken(
                const models.TokenResponse(accessToken: '', refreshToken: ''),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final newToken = await container
            .read(authTokenProvider.notifier)
            .refreshAccessToken();

        expect(newToken, jwt);
        // The provider state now carries the fresh session: the whole app
        // (middlewares, authenticator) reads from here.
        expect(
          container.read(authTokenProvider).value!.refreshToken,
          'rotated-refresh',
        );
        expect(container.read(isLoggedInProvider), isTrue);
      },
    );

    test('rethrows when the repository refresh fails', () async {
      final authRepository = MockAuthRepository();
      when(() => authRepository.refreshToken()).thenThrow(Exception('expired'));
      final container = ProviderContainer(
        overrides: [
          isConnectedProvider.overrideWith(() => _StaticIsConnected(true)),
          authRepositoryProvider.overrideWithValue(authRepository),
          authTokenProvider.overrideWith(
            () => FakeOpenIdToken(
              const models.TokenResponse(accessToken: '', refreshToken: ''),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(authTokenProvider.notifier).refreshAccessToken(),
        throwsA(isA<Exception>()),
      );
      // The failed refresh surfaces as an error state, not a session.
      expect(container.read(authTokenProvider), isA<AsyncError>());
    });
  });
}
