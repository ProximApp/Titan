// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/is_admin_provider.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/login/router.dart';
import 'package:titan/router.dart';
import 'package:titan/super_admin/providers/is_super_admin_provider.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';
import 'package:titan/tools/middlewares/authenticated_middleware.dart';
import 'package:titan/tools/class/path_forwarding.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/version/providers/titan_version_provider.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

/// The guard only reads snapshots, so each arm is reached by pinning the
/// providers it reads: the login state, the module roots the account may open,
/// the forwarding notifier, the backend version check and the local build
/// number that check is compared against.
class _FakeVerifier extends VersionVerifierNotifier {
  _FakeVerifier(this.value);

  final AsyncValue<CoreInformation> value;

  @override
  AsyncValue<CoreInformation> build() => value;
}

class _BuildNumber extends TitanVersionNotifier {
  @override
  int build() => 0;
}

class _LoggedIn extends IsLoggedInProvider {
  _LoggedIn(this.value);

  final bool value;

  @override
  bool build() => value;
}

/// Hands the middleware a `Ref`, which is all it keeps from the container.
final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer({
    bool loggedIn = true,
    AsyncValue<CoreInformation>? verifier,
    List<String> roots = const ['/feed'],
    String forwardingPath = '/',
    bool forwardingIsLoggedIn = false,
    bool admin = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        versionVerifierProvider.overrideWith(
          () => _FakeVerifier(
            verifier ?? AsyncValue.data(CoreInformation.empty()),
          ),
        ),
        titanVersionProvider.overrideWith(_BuildNumber.new),
        isLoggedInProvider.overrideWith(() => _LoggedIn(loggedIn)),
        moduleRootListProvider.overrideWithValue(AsyncValue.data(roots)),
        isAdminProvider.overrideWithValue(admin),
        isSuperAdminProvider.overrideWithValue(admin),
      ],
    );
    addTearDown(container.dispose);
    if (forwardingPath != '/') {
      container.read(pathForwardingProvider.notifier).forward(forwardingPath);
      if (forwardingIsLoggedIn) {
        container.read(pathForwardingProvider.notifier).login();
      }
    }
    return container;
  }

  AuthenticatedMiddleware middlewareOn(ProviderContainer container) =>
      AuthenticatedMiddleware(container.read(_refProvider));

  group('AuthenticatedMiddleware', () {
    test('the login route is let through while still signed out', () async {
      final container = makeContainer(loggedIn: false);

      final next = await middlewareOn(container)
          .redirectGuard(LoginRouter.root);

      expect(next, isNull);
      expect(container.read(pathForwardingProvider).isLoggedIn, isFalse);
    });

    test('landing on the root lands on the feed when roots exist', () async {
      final container = makeContainer();

      final next = await middlewareOn(container).redirectGuard('/');

      expect(next, FeedRouter.root);
      expect(container.read(pathForwardingProvider).path, FeedRouter.root);
      expect(container.read(pathForwardingProvider).isLoggedIn, isTrue);
    });

    test('a remembered path wins over the one being navigated to', () async {
      final container = makeContainer(
        forwardingPath: '/loan/list',
        forwardingIsLoggedIn: true,
      );

      final next = await middlewareOn(container).redirectGuard('/loan/new');

      expect(next, '/loan/list');
      expect(container.read(pathForwardingProvider).path, '/loan/list');
    });

    test('a post-sign-in forwarding is reset to the root', () async {
      final container = makeContainer(forwardingPath: '/loan/list');

      final next = await middlewareOn(container).redirectGuard('/loan/list');

      expect(next, isNull);
      expect(container.read(pathForwardingProvider).path, '/');
    });

    test('a path forwarded before sign-in is kept as it is', () async {
      final container = makeContainer();
      // Signed out the guard stashes the path as pre-auth, then sign-in flips
      // the flag without touching the path.
      container.read(pathForwardingProvider.notifier).state = PathForwarding(
        path: '/loan/list',
        isLoggedIn: true,
        preAuth: true,
      );

      final next = await middlewareOn(container).redirectGuard('/loan/list');

      expect(next, isNull);
      expect(container.read(pathForwardingProvider).path, '/loan/list');
    });

    test('a signed-in account without roots is sent to no-module', () async {
      final container = makeContainer(roots: const []);

      final next = await middlewareOn(container).redirectGuard('/');

      expect(next, AppRouter.noModule);
    });

    test('an admin without roots still lands on the feed', () async {
      final container = makeContainer(roots: const [], admin: true);

      final next = await middlewareOn(container).redirectGuard('/');

      expect(next, FeedRouter.root);
    });

    test('a pending version check routes to the loading page', () async {
      final container = makeContainer(
        verifier: const AsyncValue<CoreInformation>.loading(),
      );

      final next = await middlewareOn(container).redirectGuard(FeedRouter.root);

      expect(next, AppRouter.loading);
    });

    test('a failed version check routes to the no-internet page', () async {
      final container = makeContainer(
        verifier: AsyncValue.error(StateError('offline'), StackTrace.empty),
      );

      final next = await middlewareOn(container).redirectGuard(FeedRouter.root);

      expect(next, AppRouter.noInternet);
    });

    test('a stale build routes to the update page', () async {
      final container = makeContainer(
        verifier: const AsyncValue.data(
          CoreInformation(
            ready: true,
            version: '2',
            minimalTitanVersionCode: 5,
          ),
        ),
      );

      final next = await middlewareOn(container).redirectGuard(FeedRouter.root);

      expect(next, AppRouter.update);
    });
  });
}
