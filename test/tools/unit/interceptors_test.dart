import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/tools/interceptors/auth_interceptor.dart';
import 'package:titan/tools/interceptors/log_interceptor.dart';
import 'package:titan/tools/logs/logger.dart';

class RecordingLogger extends Logger {
  final List<String> errors = [];

  @override
  Future<void> init() async {}

  @override
  void error(String message) {
    errors.add(message);
  }
}

class _Chain<BodyType> implements chopper.Chain<BodyType> {
  _Chain(this.request, this.response);

  @override
  final chopper.Request request;

  final chopper.Response<BodyType> response;
  chopper.Request? lastRequest;

  @override
  Future<chopper.Response<BodyType>> proceed(chopper.Request request) async {
    lastRequest = request;
    return response;
  }
}

chopper.Request request() => chopper.Request(
  'GET',
  Uri.parse('https://t.example/x'),
  Uri.parse('https://t.example'),
);

void main() {
  group('AuthInterceptor', () {
    test('adds the bearer header when a token is present', () async {
      final interceptor = AuthInterceptor(token: 'abc');
      final chain = _Chain<String>(
        request(),
        chopper.Response<String>(http.Response('ok', 200), 'ok'),
      );

      await interceptor.intercept<String>(chain);

      expect(chain.lastRequest!.headers['Authorization'], 'Bearer abc');
    });

    test('exposes the bearer header map', () {
      expect(AuthInterceptor(token: '').headers, isEmpty);
      expect(
        AuthInterceptor(token: 'abc').headers['Authorization'],
        'Bearer abc',
      );
    });
  });

  group('LogInterceptor', () {
    test('logs error responses', () async {
      final logger = RecordingLogger();
      final interceptor = LogInterceptor(logger: logger);
      final chain = _Chain<String>(
        request(),
        chopper.Response<String>(http.Response('boom', 500), 'boom'),
      );

      final result = await interceptor.intercept<String>(chain);

      expect(result.statusCode, 500);
      expect(logger.errors, hasLength(1));
      expect(logger.errors.single, contains('500'));
      expect(logger.errors.single, contains('boom'));
    });

    test('does not log successful responses', () async {
      final logger = RecordingLogger();
      final interceptor = LogInterceptor(logger: logger);
      final chain = _Chain<String>(
        request(),
        chopper.Response<String>(http.Response('ok', 200), 'ok'),
      );

      final result = await interceptor.intercept<String>(chain);

      expect(result.statusCode, 200);
      expect(logger.errors, isEmpty);
    });
  });
}
