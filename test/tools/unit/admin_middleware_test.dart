import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/tools/middlewares/admin_middleware.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

/// `waitForFirstValue` is what keeps a cold deep link into a gated route from
/// being judged on the loading state: the guard polls each source until it
/// answers. A source that is already settled must not cost a single frame.
void main() {
  // Reading the forwarding state consults the logged-in provider, which reads
  // its stored session through a platform channel.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a settled source answers without polling', () async {
    var calls = 0;

    await waitForFirstValue(() {
      calls++;
      return false;
    });

    expect(calls, 1);
  });

  test('a loading source is polled until it settles', () async {
    var calls = 0;

    await waitForFirstValue(() => ++calls < 4);

    expect(calls, 4);
  });

  test('every source is drained before the gate is read', () async {
    final polled = <String>[];

    await waitForFirstValue(() {
      polled.add('structures');
      return polled.length < 3;
    });
    await waitForFirstValue(() {
      polled.add('loaners');
      return false;
    });

    expect(polled, ['structures', 'structures', 'structures', 'loaners']);
  });

  group('redirectGuard', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('an admin is left on the route', () async {
      final middleware = AdminMiddleware(
        container.read(_refProvider),
        Provider((ref) => true),
        isLoading: [() => false],
      );

      expect(await middleware.redirectGuard('/anything'), isNull);
      // Untouched: still the initial "/" of PathForwarding.empty().
      expect(container.read(pathForwardingProvider).path, '/');
    });

    test('a non-admin is forwarded to the feed', () async {
      final middleware = AdminMiddleware(
        container.read(_refProvider),
        Provider((ref) => false),
      );

      expect(await middleware.redirectGuard('/anything'), FeedRouter.root);
      expect(container.read(pathForwardingProvider).path, FeedRouter.root);
    });
  });
}

/// `AdminMiddleware` takes a riverpod `Ref`, which only a provider can hand
/// out; this exposes the container's ref to the test.
final _refProvider = Provider<Ref>((ref) => ref);
