import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

class _TokenEndpoint implements Openapi {
  final requests = <Map<String, String>>[];
  int statusCode = 200;
  models.TokenResponse? responseBody = const models.TokenResponse(
    accessToken: 'web-access',
    refreshToken: 'rotated-refresh',
  );

  @override
  Future<chopper.Response<models.TokenResponse>> authTokenPost({
    String? authorization,
    required Map<String, String> body,
  }) async {
    requests.add(body);
    return chopper.Response<models.TokenResponse>(
      http.Response('response', statusCode),
      responseBody,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected Openapi call: ${invocation.memberName}',
  );
}

const _secureStorage = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _TokenEndpoint endpoint;
  final stored = <String, String>{};
  final deleted = <String>[];

  setUp(() {
    endpoint = _TokenEndpoint();
    stored.clear();
    deleted.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, (call) async {
          final key = call.arguments['key'] as String;
          switch (call.method) {
            case 'read':
              return stored[key];
            case 'write':
              stored[key] = call.arguments['value'] as String;
            case 'delete':
              deleted.add(key);
              stored.remove(key);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_secureStorage, null),
    );
  });

  AuthRepository repository() => AuthRepository(openIdRepository: endpoint);

  group('AuthRepository web refresh-token grant', () {
    test(
      'sends the stored refresh token and persists token rotation',
      () async {
        stored['my_ecl_auth_token'] = 'old-refresh';

        final tokens = await repository().refreshToken();

        expect(endpoint.requests, [
          {
            'client_id': 'Titan',
            'grant_type': 'refresh_token',
            'refresh_token': 'old-refresh',
          },
        ]);
        expect(tokens.accessToken, 'web-access');
        expect(tokens.refreshToken, 'rotated-refresh');
        expect(stored['my_ecl_auth_token'], 'rotated-refresh');
        expect(deleted, isEmpty);
      },
    );

    for (final status in [400, 401]) {
      test('HTTP $status invalidates and deletes the stored token', () async {
        stored['my_ecl_auth_token'] = 'expired-refresh';
        endpoint
          ..statusCode = status
          ..responseBody = null;

        await expectLater(
          repository().refreshToken(),
          throwsA(isA<Exception>()),
        );

        expect(endpoint.requests, hasLength(1));
        expect(deleted, ['my_ecl_auth_token']);
        expect(stored, isEmpty);
      });
    }

    test('a server error keeps the stored token available for retry', () async {
      stored['my_ecl_auth_token'] = 'still-valid-refresh';
      endpoint
        ..statusCode = 503
        ..responseBody = null;

      await expectLater(repository().refreshToken(), throwsA(isA<Exception>()));

      expect(deleted, isEmpty);
      expect(stored['my_ecl_auth_token'], 'still-valid-refresh');
    });
  });
}
