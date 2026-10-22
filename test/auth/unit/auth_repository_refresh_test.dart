import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;

import '../../shared/mock_openapi.dart';

chopper.Response<T> chopperResponse<T>(T body) =>
    chopper.Response(http.Response('body', 200), body);

/// The 1x1 PNG of the token world: an access token the real JwtDecoder
/// accepts and reports as non-expired.
const validJwt =
    'eyJhbGciOiAiUlMyNTYiLCAidHlwIjogIkpXVCJ9.'
    'eyJzdWIiOiAidXNlci00MiIsICJleHAiOiA0MTAyNDQ0ODAwfQ.sig';

const platformInterfaceChannel = MethodChannel(
  'crossingthestreams.io/flutter_appauth',
);
const secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOpenapi repository;
  final stored = <String, String>{};
  final deleted = <String>[];

  setUp(() {
    repository = MockOpenapi();
    SharedPreferences.setMockInitialValues({});
    stored.clear();
    deleted.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          if (call.method == 'read') {
            return stored[call.arguments['key']];
          }
          if (call.method == 'write') {
            stored[call.arguments['key']] = call.arguments['value'];
            return null;
          }
          if (call.method == 'delete') {
            deleted.add(call.arguments['key']);
            stored.remove(call.arguments['key']);
            return null;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, null),
    );
  });

  void stubAppAuthToken(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformInterfaceChannel, handler);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platformInterfaceChannel, null),
    );
  }

  group('AuthRepository helpers', () {
    test('generates a verifier with the requested length and alphabet', () {
      final repo = AuthRepository(openIdRepository: repository);

      final verifier = repo.generateRandomString(128);

      expect(verifier, hasLength(128));
      expect(verifier, matches(RegExp(r'^[A-Za-z0-9]{128}$')));
    });

    test('hashes the PKCE verifier as a URL-safe SHA-256 digest', () {
      final repo = AuthRepository(openIdRepository: repository);

      expect(
        repo.hash('challenge'),
        'LdAL134CIs7YgmZUganB2fkHMJ0W4F7QB6HqY5KEd6k=',
      );
    });

    test('stores a valid token response in secure storage', () async {
      final repo = AuthRepository(openIdRepository: repository);

      await repo.storeToken(
        const models.TokenResponse(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        ),
      );

      expect(stored['my_ecl_auth_token'], 'refresh-token');
    });

    test('rejects a token response with an empty token', () async {
      final repo = AuthRepository(openIdRepository: repository);

      await expectLater(
        repo.storeToken(
          const models.TokenResponse(accessToken: '', refreshToken: 'refresh'),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repo.storeToken(
          const models.TokenResponse(accessToken: 'access', refreshToken: ''),
        ),
        throwsA(isA<Exception>()),
      );
      expect(stored, isEmpty);
    });

    test('deletes the secure token and cached session data', () async {
      final repo = AuthRepository(openIdRepository: repository);
      stored['my_ecl_auth_token'] = 'refresh-token';
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('my_ecl_auth_token', 'cached-token');
      await preferences.setString('id', 'user-42');

      await repo.deleteToken();

      expect(stored, isEmpty);
      expect(deleted, contains('my_ecl_auth_token'));
      expect(preferences.getString('my_ecl_auth_token'), isNull);
      expect(preferences.getString('id'), isNull);
    });
  });

  group('AuthRepository.refreshToken (native shell)', () {
    test(
      'exchanges the stored refresh token and persists the new one',
      () async {
        final repo = AuthRepository(openIdRepository: repository);
        stored['my_ecl_auth_token'] = 'stored-refresh';
        stubAppAuthToken((call) async {
          expect(call.method, 'token');
          // The request carries the stored refresh token for the grant.
          expect(call.arguments['refreshToken'], 'stored-refresh');
          return <String, dynamic>{
            'accessToken': validJwt,
            'refreshToken': 'rotated-refresh',
          };
        });

        final tokens = await repo.refreshToken();

        expect(tokens.accessToken, validJwt);
        expect(tokens.refreshToken, 'rotated-refresh');
        // The rotation is persisted for the next cold start.
        expect(stored['my_ecl_auth_token'], 'rotated-refresh');
        expect(deleted, isEmpty);
      },
    );

    test('fails fast when no refresh token is stored', () async {
      final repo = AuthRepository(openIdRepository: repository);
      var appAuthCalled = false;
      stubAppAuthToken((call) async {
        appAuthCalled = true;
        return <String, dynamic>{};
      });

      await expectLater(repo.refreshToken(), throwsA(isA<Exception>()));
      expect(appAuthCalled, isFalse);
    });

    test('deduplicates concurrent refreshes into one round-trip', () async {
      final repo = AuthRepository(openIdRepository: repository);
      stored['my_ecl_auth_token'] = 'stored-refresh';
      var calls = 0;
      stubAppAuthToken((call) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return <String, dynamic>{
          'accessToken': validJwt,
          'refreshToken': 'rotated-refresh',
        };
      });

      final results = await Future.wait([
        repo.refreshToken(),
        repo.refreshToken(),
        repo.refreshToken(),
      ]);

      expect(calls, 1);
      // Every caller receives the same rotated token.
      expect(
        results.map((r) => r.refreshToken),
        everyElement('rotated-refresh'),
      );
    });

    test(
      'wipes the stored token when the grant is invalid (invalid_grant)',
      () async {
        final repo = AuthRepository(openIdRepository: repository);
        stored['my_ecl_auth_token'] = 'expired-refresh';
        stubAppAuthToken((call) async {
          // The platform shell surfaces OAuth invalid_grant as a platform
          // exception with the error in its details.
          throw PlatformException(
            code: 'authorize_failed',
            details: {
              'type': 'oauth_error',
              'error': FlutterAppAuthOAuthError.invalidGrant,
            },
          );
        });

        await expectLater(repo.refreshToken(), throwsA(isA<Exception>()));
        // The dead refresh token is deleted: the next sign-in starts clean.
        expect(deleted, contains('my_ecl_auth_token'));
        expect(stored.containsKey('my_ecl_auth_token'), isFalse);
      },
    );

    test('keeps the stored token on a non-OAuth failure', () async {
      final repo = AuthRepository(openIdRepository: repository);
      stored['my_ecl_auth_token'] = 'stored-refresh';
      stubAppAuthToken((call) async {
        throw PlatformException(
          code: 'network_error',
          details: {'type': 'network', 'error': 'server_error'},
        );
      });

      await expectLater(repo.refreshToken(), throwsA(isA<Exception>()));
      // A network failure must not log the user out.
      expect(deleted, isEmpty);
      expect(stored['my_ecl_auth_token'], 'stored-refresh');
    });
  });

  group('AuthRepository.getTokenFromRequest (native shell)', () {
    test('stores tokens returned by the authorization shell', () async {
      final repo = AuthRepository(openIdRepository: repository);
      stubAppAuthToken((call) async {
        expect(call.method, 'authorizeAndExchangeCode');
        return <String, dynamic>{
          'accessToken': validJwt,
          'refreshToken': 'authorization-refresh',
        };
      });

      final tokens = await repo.getTokenFromRequest();

      expect(tokens.accessToken, validJwt);
      expect(tokens.refreshToken, 'authorization-refresh');
      expect(stored['my_ecl_auth_token'], 'authorization-refresh');
    });

    test(
      'reports wrong credentials when the shell hands back no token',
      () async {
        final repo = AuthRepository(openIdRepository: repository);
        stubAppAuthToken((call) async {
          expect(call.method, 'authorizeAndExchangeCode');
          // A cancelled or empty authorization: no token in the reply.
          return <String, dynamic>{};
        });

        await expectLater(
          repo.getTokenFromRequest(),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('AuthRepository.refreshToken native failure branches', () {
    test('throws when the shell returns no access token', () async {
      final repo = AuthRepository(openIdRepository: repository);
      stored['my_ecl_auth_token'] = 'stored-refresh';
      stubAppAuthToken((call) async {
        expect(call.method, 'token');
        return <String, dynamic>{'refreshToken': 'rotated-refresh'};
      });

      await expectLater(repo.refreshToken(), throwsA(isA<Exception>()));
      // A dead-end reply must not be mistaken for an invalid grant.
      expect(deleted, isEmpty);
      expect(stored['my_ecl_auth_token'], 'stored-refresh');
    });
  });

  test('getTokenFromStorage delegates to refreshToken', () async {
    final repo = AuthRepository(openIdRepository: repository);
    stored['my_ecl_auth_token'] = 'stored-refresh';
    stubAppAuthToken((call) async {
      expect(call.method, 'token');
      return <String, dynamic>{
        'accessToken': validJwt,
        'refreshToken': 'rotated-refresh',
      };
    });

    final tokens = await repo.getTokenFromStorage();

    expect(tokens.accessToken, validJwt);
    expect(stored['my_ecl_auth_token'], 'rotated-refresh');
  });

  group('authRepositoryProvider', () {
    test('builds the repository against the configured host', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authRepositoryProvider), isA<AuthRepository>());
    });
  });
}
