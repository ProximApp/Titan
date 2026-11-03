import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/class/path_forwarding.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

/// A logged-in answer without pulling the auth chain (cache, plugins) into
/// the test: `forward` reads this only when the path actually changes.
class _AlwaysLoggedIn extends IsLoggedInProvider {
  @override
  bool build() => true;
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [isLoggedInProvider.overrideWith(_AlwaysLoggedIn.new)],
    );
    addTearDown(container.dispose);
  });

  PathForwardingProvider notifier() =>
      container.read(pathForwardingProvider.notifier);

  PathForwarding state() => container.read(pathForwardingProvider);

  test('forwards a new path with its query parameters', () {
    notifier().forward('/tickets', queryParameters: {'code': 'ABC'});

    expect(state().path, '/tickets');
    expect(state().queryParameters, {'code': 'ABC'});
    expect(state().isLoggedIn, isFalse);
  });

  test('forwarding the same path keeps the computed preAuth', () {
    notifier().forward('/vote');
    notifier().forward('/vote', queryParameters: {'id': '1'});

    expect(state().path, '/vote');
    expect(state().queryParameters, {'id': '1'});
  });

  test('login flips only the logged-in flag', () {
    notifier().forward('/vote');
    notifier().login();

    expect(state().isLoggedIn, isTrue);
    expect(state().path, '/vote');
  });

  test('clearParams leaves the path in place', () {
    notifier().forward('/vote', queryParameters: {'a': '1'});
    notifier().clearParams();

    expect(state().path, '/vote');
  });

  test('removeQueryParam drops one key and clears the map when empty', () {
    notifier().forward('/vote', queryParameters: {'a': '1', 'b': '2'});

    notifier().removeQueryParam('a');
    expect(state().queryParameters, {'b': '2'});

    notifier().removeQueryParam('b');
    expect(state().queryParameters, isNull);
    expect(state().path, '/vote');
  });

  test('removeQueryParam is a no-op without parameters', () {
    notifier().forward('/vote');

    notifier().removeQueryParam('a');

    expect(state().queryParameters, isNull);
    expect(state().path, '/vote');
  });

  test('reset returns to the empty forwarding state', () {
    notifier().forward('/vote', queryParameters: {'a': '1'});
    notifier().reset();

    expect(state().path, '/');
    expect(state().queryParameters, isNull);
    expect(state().isLoggedIn, isFalse);
  });
}
