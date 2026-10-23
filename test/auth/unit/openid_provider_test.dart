import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/auth/providers/is_connected_provider.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// A token that survives a refresh in the native shell: the repository reads
/// it straight back out of the appauth `token` channel response.
const storedJwt = 'stored-access-token';

/// A JWT whose `sub` claim the real JwtDecoder decodes to `user-42`.
const validJwt =
    'eyJhbGciOiAiUlMyNTYiLCAidHlwIjogIkpXVCJ9.'
    'eyJzdWIiOiAidXNlci00MiIsICJleHAiOiA0MTAyNDQ0ODAwfQ.sig';

const appAuthChannel = MethodChannel('crossingthestreams.io/flutter_appauth');
const secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

class _FixedIsConnected extends IsConnectedProvider {
  _FixedIsConnected(this.value);

  final bool value;

  @override
  bool build() => value;
}

class _FixedIsCaching extends IsCachingProvider {
  _FixedIsCaching(this.value);

  final bool value;

  @override
  bool build() => value;
}

class _FixedAuthRepository extends AuthRepository {
  _FixedAuthRepository(MockOpenapi repository, {required this.tokenResponse})
    : super(openIdRepository: repository);

  final models.TokenResponse tokenResponse;

  @override
  Future<models.TokenResponse> getTokenFromRequest() async => tokenResponse;

  @override
  Future<models.TokenResponse> getTokenFromStorage() async => tokenResponse;

  @override
  Future<models.TokenResponse> refreshToken() async => tokenResponse;
}

ProviderContainer _container(
  MockOpenapi repository, {
  required bool isConnected,
  required bool isCaching,
}) => ProviderContainer(
  overrides: [
    repositoryProvider.overrideWithValue(repository),
    authRepositoryProvider.overrideWithValue(
      AuthRepository(openIdRepository: repository),
    ),
    isConnectedProvider.overrideWith(() => _FixedIsConnected(isConnected)),
    isCachingProvider.overrideWith(() => _FixedIsCaching(isCaching)),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOpenapi repository;
  final stored = <String, String>{};
  final deleted = <String>[];

  setUp(() {
    repository = MockOpenapi();
    stored.clear();
    deleted.clear();
    SharedPreferences.setMockInitialValues({});

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

  test(
    'getTokenFromStorage surfaces a data token and updates the state',
    () async {
      stored['my_ecl_auth_token'] = 'stored-refresh';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(appAuthChannel, (call) async {
            expect(call.method, 'token');
            return <String, dynamic>{
              'accessToken': storedJwt,
              'refreshToken': 'rotated-refresh',
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(appAuthChannel, null),
      );

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            AuthRepository(openIdRepository: repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = container.read(authTokenProvider.notifier);
      await provider.getTokenFromStorage();

      final value = container.read(authTokenProvider);
      expect(value.hasValue, isTrue);
      expect(value.hasError, isFalse);
      expect(value.value?.accessToken, storedJwt);
    },
  );

  test('getTokenFromStorage errors when no token is stored', () async {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(
          AuthRepository(openIdRepository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = container.read(authTokenProvider.notifier);
    await provider.getTokenFromStorage();

    expect(container.read(authTokenProvider).hasError, isTrue);
  });

  group('refreshAccessToken', () {
    test('stores the rotated token and returns the access token', () async {
      stored['my_ecl_auth_token'] = 'stored-refresh';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(appAuthChannel, (call) async {
            return <String, dynamic>{
              'accessToken': storedJwt,
              'refreshToken': 'rotated-refresh',
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(appAuthChannel, null),
      );

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            AuthRepository(openIdRepository: repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = container.read(authTokenProvider.notifier);

      final access = await provider.refreshAccessToken();

      expect(access, storedJwt);
      expect(container.read(authTokenProvider).hasValue, isTrue);
      expect(stored['my_ecl_auth_token'], 'rotated-refresh');
    });

    test(
      'rethrows and moves to the error state when the refresh fails',
      () async {
        // No stored token: the repository throws before hitting appauth.
        final container = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(repository),
            authRepositoryProvider.overrideWithValue(
              AuthRepository(openIdRepository: repository),
            ),
          ],
        );
        addTearDown(container.dispose);
        final provider = container.read(authTokenProvider.notifier);

        await expectLater(
          provider.refreshAccessToken(),
          throwsA(isA<Exception>()),
        );
        expect(container.read(authTokenProvider).hasError, isTrue);
      },
    );
  });

  group('loadingProvider', () {
    test('is true while the token is still loading', () async {
      final container = _container(
        repository,
        isConnected: false,
        isCaching: false,
      );
      addTearDown(container.dispose);

      // authTokenProvider.build leaves the state on loading, so the
      // `when(loading:)` branch reports "still loading".
      expect(await container.read(loadingProvider.future), isTrue);
    });

    test('is false when disconnected with no cached session', () async {
      final container = _container(
        repository,
        isConnected: false,
        isCaching: false,
      );
      addTearDown(container.dispose);
      final provider = container.read(authTokenProvider.notifier);
      await provider.deleteToken();

      // Not caching and the token errored: the `when(error:)` branch wins.
      expect(await container.read(loadingProvider.future), isFalse);
    });
  });

  group('idProvider', () {
    test('decodes the sub claim and writes it to the cache', () async {
      stored['my_ecl_auth_token'] = 'stored-refresh';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(appAuthChannel, (call) async {
            return <String, dynamic>{
              'accessToken': validJwt,
              'refreshToken': 'rotated-refresh',
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(appAuthChannel, null),
      );

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            AuthRepository(openIdRepository: repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = container.read(authTokenProvider.notifier);
      await provider.getTokenFromStorage();

      expect(await container.read(idProvider.future), 'user-42');
    });

    test('is empty when the token errors', () async {
      final container = _container(
        repository,
        isConnected: false,
        isCaching: false,
      );
      addTearDown(container.dispose);
      final provider = container.read(authTokenProvider.notifier);
      await provider.deleteToken();

      expect(await container.read(idProvider.future), '');
    });
  });

  test(
    'getTokenFromRequest errors when the appAuth shell is unavailable',
    () async {
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            AuthRepository(openIdRepository: repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = container.read(authTokenProvider.notifier);
      // In the test env there is no native appAuth shell, so the platform
      // channel call throws — the provider must land on the error branch.
      await provider.getTokenFromRequest();

      expect(container.read(authTokenProvider).hasError, isTrue);
    },
  );

  test(
    'an empty response from the storage grant becomes an error state',
    () async {
      stored['my_ecl_auth_token'] = 'stored-refresh';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(appAuthChannel, (call) async {
            expect(call.method, 'token');
            return <String, dynamic>{
              'accessToken': '',
              'refreshToken': 'rotated-refresh',
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(appAuthChannel, null),
      );

      final authRepository = AuthRepository(openIdRepository: repository);
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authTokenProvider.notifier).getTokenFromStorage();

      final token = container.read(authTokenProvider);
      expect(token.hasError, isTrue);
      expect(stored['my_ecl_auth_token'], 'stored-refresh');
      expect(deleted, isEmpty);
    },
  );

  test('an empty authorization response becomes an error state', () async {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(
          _FixedAuthRepository(
            repository,
            tokenResponse: models.TokenResponse.empty(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authTokenProvider.notifier).getTokenFromRequest();

    expect(container.read(authTokenProvider).hasError, isTrue);
  });

  test(
    'an empty refresh response is rejected and stored as an error',
    () async {
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            _FixedAuthRepository(
              repository,
              tokenResponse: models.TokenResponse.empty(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(authTokenProvider.notifier).refreshAccessToken(),
        throwsA(isA<Exception>()),
      );
      expect(container.read(authTokenProvider).hasError, isTrue);
    },
  );

  test('deleteToken logs out into the error state', () async {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(
          AuthRepository(openIdRepository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = container.read(authTokenProvider.notifier);
    await provider.deleteToken();

    expect(container.read(authTokenProvider).hasError, isTrue);
  });

  group('IsLoggedInProvider', () {
    test('is not logged in when disconnected and not caching', () {
      final container = _container(
        repository,
        isConnected: false,
        isCaching: false,
      );
      addTearDown(container.dispose);

      expect(container.read(isLoggedInProvider), isFalse);
    });

    test('falls back to the cached flag while disconnected', () {
      final container = _container(
        repository,
        isConnected: false,
        isCaching: true,
      );
      addTearDown(container.dispose);

      expect(container.read(isLoggedInProvider), isTrue);
    });

    test('is not logged in when connected but the token never landed', () {
      final container = _container(
        repository,
        isConnected: true,
        isCaching: false,
      );
      addTearDown(container.dispose);

      // authTokenProvider is still loading (no stored token in the test env),
      // so `_isValid` takes the orElse branch.
      expect(container.read(isLoggedInProvider), isFalse);
    });
  });
}
