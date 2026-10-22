import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/authenticator/authenticator.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;

chopper.Request request({Map<String, String> headers = const {}}) =>
    chopper.Request(
      'GET',
      Uri.parse('https://titan.example.com/api/v1/test'),
      Uri.parse('https://titan.example.com'),
      headers: headers,
    );

chopper.Response<void> response(int statusCode) =>
    chopper.Response(http.Response('body', statusCode), null);

void main() {
  group('AppAuthenticator', () {
    test('passes through successful responses untouched', () async {
      var refreshCalls = 0;
      final authenticator = AppAuthenticator(
        refreshAccessToken: () async {
          refreshCalls++;
          return 'new-token';
        },
      );

      final result = await authenticator.authenticate(request(), response(200));

      expect(result, null);
      expect(refreshCalls, 0);
    });

    test('refreshes the token once on 401', () async {
      var refreshCalls = 0;
      final authenticator = AppAuthenticator(
        refreshAccessToken: () async {
          refreshCalls++;
          return 'new-token';
        },
      );

      final result = await authenticator.authenticate(request(), response(401));

      expect(refreshCalls, 1);
      expect(result, isNotNull);
      expect(result!.headers['Authorization'], 'Bearer new-token');
      expect(result.headers['Retry-Count'], '1');
    });

    test('gives up when the retry count is already set', () async {
      var refreshCalls = 0;
      final authenticator = AppAuthenticator(
        refreshAccessToken: () async {
          refreshCalls++;
          return 'new-token';
        },
      );

      final result = await authenticator.authenticate(
        request(headers: {'Retry-Count': '1'}),
        response(401),
      );

      expect(result, null);
      expect(refreshCalls, 0);
    });

    test('gives up when refreshing the token fails', () async {
      final authenticator = AppAuthenticator(
        refreshAccessToken: () async => throw Exception('expired session'),
      );

      final result = await authenticator.authenticate(request(), response(401));

      expect(result, null);
    });

    test('shares a single refresh between concurrent 401s', () async {
      var refreshCalls = 0;
      final authenticator = AppAuthenticator(
        refreshAccessToken: () async {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 'shared-token';
        },
      );

      final first = authenticator.authenticate(request(), response(401));
      final second = authenticator.authenticate(request(), response(401));
      final results = await Future.wait<chopper.Request?>([
        Future.value(first),
        Future.value(second),
      ]);

      expect(refreshCalls, 1);
      expect(results[0]!.headers['Authorization'], 'Bearer shared-token');
      expect(results[1]!.headers['Authorization'], 'Bearer shared-token');
    });
  });
}
