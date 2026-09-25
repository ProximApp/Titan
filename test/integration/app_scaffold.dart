import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/mypayment/providers/key_service_provider.dart';
import 'package:titan/mypayment/tools/key_service.dart';
import 'package:titan/navigation/providers/navbar_animation.dart';
import 'package:titan/navigation/providers/should_setup_provider.dart';
import 'package:titan/router.dart';
import 'package:titan/service/class/firebase_toke_expiration.dart';
import 'package:titan/service/providers/firebase_token_expiration_provider.dart';
import 'package:titan/service/providers/firebase_token_provider.dart';
import 'package:titan/super_admin/providers/permission_name_list_provider.dart';
import 'package:titan/tools/ui/layouts/app_template.dart';
import 'package:titan/super_admin/providers/permissions_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';
import 'package:titan/version/providers/titan_version_provider.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';

class MockRepository extends Mock implements Openapi {}

/// The real KeyService reads the APP_ID_PREFIX dart-define at construction
/// and throws without it; the payment pages only read it from the provider,
/// so a mock keeps every test command free of build-specific defines.
class FakeKeyService extends Mock implements KeyService {}

/// The real verifier calls the backend through the repository; the middleware
/// only needs the data branch to decide the app is up to date.
class FakeVersionVerifierNotifier extends VersionVerifierNotifier {
  @override
  AsyncValue<CoreInformation> build() => AsyncValue.data(
    CoreInformation(ready: true, version: '1.0.0', minimalTitanVersionCode: 1),
  );
}

/// The real notifier calls PackageInfo.fromPlatform(), which has no platform
/// channel in tests; the middleware only needs an int to compare against the
/// backend's minimal version.
class FakeTitanVersionNotifier extends TitanVersionNotifier {
  @override
  int build() => 999;
}

/// The real provider derives the session from the OIDC token storage, which
/// does not exist in the test environment; the flow under test needs a user
/// that is already signed in.
class FakeIsLoggedInNotifier extends IsLoggedInProvider {
  @override
  bool build() => true;
}

/// The real notifier fetches the user from the backend; the module catalog
/// only needs the user record to compute the granted module roots.
class FakeAsyncUserNotifier extends UserNotifier {
  FakeAsyncUserNotifier(this.user);

  final CoreUser user;

  @override
  AsyncValue<CoreUser> build() => AsyncValue.data(user);
}

/// The real notifiers fetch the permission catalog; the module catalog only
/// needs the loading state resolved.
class FakePermissionsNamesListNotifier extends PermissionsNamesListNotifier {
  @override
  AsyncValue<List<String>> build() => AsyncValue.data(const []);
}

class FakePermissionsNotifier extends PermissionsNotifier {
  @override
  AsyncValue<List<CorePermission>> build() => AsyncValue.data(const []);
}

/// The real notifier reads the shared preferences cache; the notification
/// setup only needs a never-expiring record to skip re-registering tokens.
class FakeFirebaseTokenExpirationNotifier
    extends FirebaseTokenExpirationNotifier {
  @override
  FirebaseTokenExpiration build() => FirebaseTokenExpiration(
    'me',
    DateTime.now().add(const Duration(days: 30)),
  );
}

/// The real provider defaults to true, which triggers the notification setup
/// (Firebase, local notifications) for signed-in users; none of that exists
/// in the test environment.
class FakeShouldSetupNotifier extends ShouldSetupProvider {
  @override
  bool build() => false;
}

/// Boots the full real route table through the real Qlevar delegate: real
/// middlewares, real deferred page loading, real l10n and the real
/// NavigationTemplate — only the network edge and the session bootstrap are
/// mocked. Shared by every main-page integration test.
class IntegrationScaffold {
  final MockRepository repository = MockRepository();

  /// [userId] overrides the JWT-derived session id consumed by pages that
  /// fetch user-scoped data (raffle tickets, amap cash and orders).
  ProviderContainer makeContainer({CoreUser? user, String? userId}) {
    return ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        versionVerifierProvider.overrideWith(FakeVersionVerifierNotifier.new),
        titanVersionProvider.overrideWith(FakeTitanVersionNotifier.new),
        isLoggedInProvider.overrideWith(FakeIsLoggedInNotifier.new),
        userProvider.overrideWithValue(user ?? CoreUser.empty()),
        keyServiceProvider.overrideWith((ref) => FakeKeyService()),
        if (userId != null)
          idProvider.overrideWith((ref) => Future<String>.value(userId)),
        // NavigationTemplate runs the notification setup for any non-empty
        // user when shouldSetup is true; both Firebase providers hit platform
        // channels that do not exist in tests.
        firebaseTokenProvider.overrideWithValue(Future.value('test-token')),
        shouldSetupProvider.overrideWith(FakeShouldSetupNotifier.new),
      ],
    );
  }

  /// Same as [makeContainer] but resolves the module catalog chain (user,
  /// permissions, permission names) without backend calls. Pages backed by
  /// modulesProvider — the all-modules page, the navbar — need this.
  ProviderContainer makeContainerWithModules({CoreUser? user}) {
    return ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        versionVerifierProvider.overrideWith(FakeVersionVerifierNotifier.new),
        titanVersionProvider.overrideWith(FakeTitanVersionNotifier.new),
        isLoggedInProvider.overrideWith(FakeIsLoggedInNotifier.new),
        userProvider.overrideWithValue(user ?? CoreUser.empty()),
        asyncUserProvider.overrideWith(
          () => FakeAsyncUserNotifier(user ?? CoreUser.empty()),
        ),
        permissionsNamesListProvider.overrideWith(
          FakePermissionsNamesListNotifier.new,
        ),
        permissionsProvider.overrideWith(FakePermissionsNotifier.new),
        // NavigationTemplate runs the notification setup for signed-in users
        // on non-web platforms; both Firebase providers hit platform
        // channels that do not exist in tests.
        firebaseTokenProvider.overrideWithValue(Future.value('test-token')),
        firebaseTokenExpirationProvider.overrideWith(
          () => FakeFirebaseTokenExpirationNotifier(),
        ),
        shouldSetupProvider.overrideWith(FakeShouldSetupNotifier.new),
      ],
    );
  }

  Future<void> pumpApp(
    WidgetTester tester,
    ProviderContainer container, {
    String initialPath = AppRouter.root,
    bool pumpAndSettle = true,
  }) async {
    // The real app wires the navbar animation controller in main.dart;
    // NavigationTemplate unwraps it with `animation!` and only shows the
    // navbar when the animation is completed, so a finished controller has
    // to be in place before any page renders.
    final animationNotifier = container.read(navbarAnimationProvider.notifier);
    final navbarController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    addTearDown(navbarController.dispose);
    animationNotifier.setController(navbarController);
    // The middleware flips this on the first real redirect; the navbar is
    // only rendered for users it considers signed in. It is intentionally
    // NOT forwarded to a path: forward(path) would make every later
    // redirectGuard bounce the router back to that first path.

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
          // The real app wraps every routed page in AppTemplate through this
          // builder; without it the NavigationTemplate (navbar, quit dialog)
          // never mounts.
          builder: (context, child) =>
              child == null ? const SizedBox() : AppTemplate(child: child),
          routeInformationParser: const QRouteInformationParser(),
          routerDelegate: QRouterDelegate(
            container.read(appRouterProvider).routes,
            initPath: initialPath,
          ),
        ),
      ),
    );
    if (pumpAndSettle) {
      await tester.pumpAndSettle();
    } else {
      // Pages with a permanently-active animation (a loader over a provider
      // that never resolves, a repeating timer) never settle; pump a fixed
      // number of frames instead so the test still observes rendered state.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }
  }

  /// Stubs the connectivity probe the session bootstrap watches.
  void stubInformation() {
    when(() => repository.informationGet()).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        CoreInformation(
          ready: true,
          version: '1.0.0',
          minimalTitanVersionCode: 1,
        ),
      ),
    );
  }

  /// Stubs the feed endpoints the boot redirect chain touches: '/' forwards
  /// to /feed through AuthenticatedMiddleware before the page under test is
  /// processed, so every initial-path test needs these in place.
  void stubFeed() {
    when(() => repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), <News>[]),
    );
    when(
      () => repository.feedNewsNewsIdImageGet(newsId: any(named: 'newsId')),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  }

  /// Stubs the profile picture (a 404 reads as "no bytes" and falls back to
  /// the placeholder asset instead of crashing).
  void stubProfilePicture() {
    when(
      () =>
          repository.usersUserIdProfilePictureGet(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  }
}
