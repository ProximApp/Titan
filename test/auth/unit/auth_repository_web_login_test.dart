import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

/// The token endpoint, recording every exchange body it is asked to send.
class _CodeEndpoint implements Openapi {
  final requests = <Map<String, String>>[];
  int statusCode = 200;
  models.TokenResponse? responseBody = const models.TokenResponse(
    accessToken: 'web-access',
    refreshToken: 'rotated-refresh',
  );

  /// Thrown instead of answering, for the failures a status code cannot model
  /// (a stalled grant arrives as a TimeoutException, not a response).
  Object? throwOnExchange;

  @override
  Future<chopper.Response<models.TokenResponse>> authTokenPost({
    String? authorization,
    required Map<String, String> body,
  }) async {
    requests.add(body);
    final failure = throwOnExchange;
    if (failure != null) throw failure;
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

/// Stands in for the popup shim: records the URL it was asked to open and
/// keeps the callbacks, so each test decides what the browser does next.
class _FakePopup {
  String? url;
  String? name;
  void Function()? onClosed;
  Future<void> Function(String)? onLogin;
  void Function()? onBlocked;
  var opened = 0;

  void open(
    String windowUrl,
    String windowName, {
    required void Function() completerFutureCallback,
    required Future<void> Function(String) loginCallback,
    void Function()? popupBlockedCallback,
  }) {
    opened++;
    url = windowUrl;
    name = windowName;
    onClosed = completerFutureCallback;
    onLogin = loginCallback;
    onBlocked = popupBlockedCallback;
  }
}

const _secureStorage = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _CodeEndpoint endpoint;
  late _FakePopup popup;
  final stored = <String, String>{};

  setUp(() {
    endpoint = _CodeEndpoint();
    popup = _FakePopup();
    stored.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, (call) async {
          final key = call.arguments['key'] as String;
          switch (call.method) {
            case 'read':
              return stored[key];
            case 'write':
              stored[key] = call.arguments['value'] as String;
            case 'delete':
              stored.remove(key);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_secureStorage, null),
    );
  });

  AuthRepository repository() => AuthRepository(
    openIdRepository: endpoint,
    isWeb: true,
    openWindow: popup.open,
  );

  /// What the shim does when the popup posts its result back to us.
  Future<void> postBack(String data) => popup.onLogin!(data);

  group('AuthRepository web authorization-code grant', () {
    test('opens the popup on the PKCE authorize URL', () async {
      final future = repository().getTokenFromRequest();

      final url = popup.url ?? '';
      expect(popup.opened, 1);
      expect(popup.name, 'Hyperion');
      expect(url, contains('auth/authorize?client_id=Titan'));
      expect(url, contains('response_type=code'));
      expect(url, contains('scope=API'));
      expect(url, contains('redirect_uri='));
      expect(url, contains('code_challenge='));
      expect(url, contains('code_challenge_method=S256'));

      popup.onClosed!();
      expect((await future).accessToken, isEmpty);
    });

    test('exchanges the posted code and persists the rotated token', () async {
      final future = repository().getTokenFromRequest();

      await postBack('https://titan.test/static.html?code=abc123&state=x');

      final tokens = await future;
      expect(tokens.accessToken, 'web-access');
      expect(tokens.refreshToken, 'rotated-refresh');
      expect(endpoint.requests, hasLength(1));
      final body = endpoint.requests.single;
      expect(body['code'], 'abc123');
      expect(body['grant_type'], 'authorization_code');
      expect(body['client_id'], 'Titan');
      expect(body['redirect_uri'], contains('static.html'));
      // The verifier is regenerated per attempt and sent back for the
      // PKCE proof; its length is the contract the server checks.
      expect(body['code_verifier'], hasLength(128));
      expect(stored['my_ecl_auth_token'], 'rotated-refresh');
    });

    test('a second post from the same popup is ignored', () async {
      final future = repository().getTokenFromRequest();

      await postBack('https://titan.test/static.html?code=first');
      await postBack('https://titan.test/static.html?code=second');
      await future;

      // One attempt per popup: a duplicate message must not spend a second
      // authorization code or overwrite the first result.
      expect(endpoint.requests, hasLength(1));
      expect(endpoint.requests.single['code'], 'first');
    });

    test('closing the popup without a code cancels the login', () async {
      final future = repository().getTokenFromRequest();

      popup.onClosed!();

      final tokens = await future;
      expect(tokens.accessToken, isEmpty);
      expect(tokens.refreshToken, isEmpty);
      expect(endpoint.requests, isEmpty);
    });

    test('closing the popup after the code is not a cancellation', () async {
      final future = repository().getTokenFromRequest();

      await postBack('https://titan.test/static.html?code=abc');
      // The shim closes the popup itself once it has the code, so this always
      // fires after a successful login; it must not turn it into a cancel.
      popup.onClosed!();

      expect((await future).accessToken, 'web-access');
      expect(endpoint.requests, hasLength(1));
    });

    test('a blocked popup fails instead of hanging', () async {
      final future = repository().getTokenFromRequest();

      popup.onBlocked!();

      await expectLater(
        future,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Popup blocked'),
          ),
        ),
      );
    });

    test('a rejected exchange surfaces as wrong credentials', () async {
      endpoint
        ..statusCode = 400
        ..responseBody = null;
      final future = repository().getTokenFromRequest();

      // The callback itself swallows nothing: it completes the error, and the
      // caller awaiting the login sees it.
      await postBack('https://titan.test/static.html?code=expired');

      await expectLater(
        future,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Wrong credentials'),
          ),
        ),
      );
      expect(stored, isEmpty);
    });

    test('a redirect carrying no code is wrong credentials', () async {
      final future = repository().getTokenFromRequest();

      await postBack('https://titan.test/static.html?error=access_denied');

      await expectLater(
        future,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Wrong credentials'),
          ),
        ),
      );
      expect(endpoint.requests, isEmpty);
    });

    test('a hung exchange maps to a no-response failure', () async {
      endpoint.throwOnExchange = TimeoutException(
        'stalled',
        const Duration(seconds: 30),
      );
      final future = repository().getTokenFromRequest();

      await postBack('https://titan.test/static.html?code=abc');

      await expectLater(
        future,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No response from server'),
          ),
        ),
      );
    });
  });
}
