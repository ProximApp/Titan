import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/tools/authenticator/authenticator.dart';
import 'package:titan/tools/interceptors/auth_interceptor.dart';
import 'package:titan/tools/interceptors/log_interceptor.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/tools/repository/repository.dart';

/// The wiring providers nothing else exercises: every other test OVERRIDES
/// `repositoryProvider`, and the interceptors are constructed directly, so
/// the three provider bodies never ran — nor did the authenticator's two
/// interface getters, which chopper only asks for on its own auth events.
class _QuietLogger extends Logger {
  @override
  Future<void> init() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The real Logger() opens a file through path_provider, which has no
    // test binding — the provider under test only needs A logger.
    container = ProviderContainer(
      overrides: [loggerProvider.overrideWithValue(_QuietLogger())],
    );
    addTearDown(container.dispose);
  });

  test('repositoryProvider builds the real chopper client', () {
    final repository = container.read(repositoryProvider);
    expect(repository, isNotNull);
  });

  test('authenticatorProvider wires the refresh callback', () {
    final authenticator = container.read(authenticatorProvider);
    expect(authenticator, isA<AppAuthenticator>());
    // The app never trips an auth event, so the two interface callbacks are
    // asserted directly: both say "no custom handling".
    expect(authenticator.onAuthenticationFailed, isNull);
    expect(authenticator.onAuthenticationSuccessful, isNull);
  });

  test('the interceptor providers bind token and logger state', () {
    expect(container.read(authInterceptorProvider), isA<AuthInterceptor>());
    expect(container.read(logInterceptorProvider), isA<LogInterceptor>());
  });
}
