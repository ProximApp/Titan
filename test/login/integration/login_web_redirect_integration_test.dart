import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/login/ui/app_sign_in.dart';
import 'package:titan/login/ui/web/web_sign_in.dart';
import 'package:titan/router.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';

import '../../shared/app_scaffold.dart';

/// The login pages' post-sign-in hand-off.
///
/// `LeftPanel` carries a copy of `AppSignIn`'s post-login effect: once the
/// session, the user, the permissions and the module catalog are all in
/// place, the page forwards to the feed instead of leaving the visitor on a
/// login form they no longer need. The router only builds `WebSignIn` behind
/// `kIsWeb`, so no host test reaches it through a deep link: this file mounts
/// it inside a real `QRouter` that carries the app's feed path, which is
/// exactly the navigation the effect performs.
///
/// Mounts a real login page inside a real `QRouter` whose login route sits at
/// [initPath], with the feed page and any extra [routes] registered as
/// hand-off targets. [page] defaults to the web page; the mobile page answers
/// the same effect.
Future<void> pumpLoginAt(
  WidgetTester tester,
  ProviderContainer container,
  String initPath, {
  Map<String, String> routes = const {},
  Widget Function()? page,
}) async {
  tester.view.physicalSize = const ui.Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await loadAppFonts();
  stubNetworkImages();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ToastificationWrapper(
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
          routeInformationParser: const QRouteInformationParser(),
          routerDelegate: QRouterDelegate([
            QRoute(
              path: initPath,
              builder: page ?? () => const WebSignIn(),
              pageType: const QMaterialPage(),
            ),
            QRoute(
              path: FeedRouter.root,
              builder: () => const Text('feed page'),
              pageType: const QMaterialPage(),
            ),
            for (final entry in routes.entries)
              QRoute(
                path: entry.key,
                builder: () => Text(entry.value),
                pageType: const QMaterialPage(),
              ),
          ], initPath: initPath),
        ),
      ),
    ),
  );
  await settle(tester, frames: 24);
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    QR.reset();
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a signed-in visit to the web login page is forwarded to the '
      'feed and the session is marked as logged in', (tester) async {
    final container = scaffold.makeContainerWithModules();
    addTearDown(container.dispose);
    // The deep link the visitor is on: the login page itself, which the
    // effect replaces with the feed.
    container.read(pathForwardingProvider.notifier).forward('/login');
    expect(container.read(pathForwardingProvider).isLoggedIn, isFalse);

    await pumpLoginAt(tester, container, '/login');

    // The effect ran: the visitor is on the feed, not on the login form.
    expect(QR.currentPath, FeedRouter.root);
    expect(find.text('feed page'), findsOneWidget);
    expect(find.byType(WaitingButton), findsNothing);
    // ...and the forwarding state now records that the visit is signed in, so
    // a later bounce cannot replay the login page over the feed.
    expect(container.read(pathForwardingProvider).isLoggedIn, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pre-auth deep link is replayed instead of the feed', (
    tester,
  ) async {
    // The visitor asked for a page before signing in; the effect must send
    // them there rather than to the feed's default landing page.
    final container = scaffold.makeContainerWithModules();
    addTearDown(container.dispose);
    container.read(pathForwardingProvider.notifier).forward('/vote/detail');

    await pumpLoginAt(
      tester,
      container,
      '/login',
      routes: {'/vote/detail': 'vote page'},
    );

    expect(QR.currentPath, '/vote/detail');
    expect(find.text('vote page'), findsOneWidget);
    expect(find.text('feed page'), findsNothing);
    expect(container.read(pathForwardingProvider).isLoggedIn, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a login page built while the navigator still reports the app '
      'root still forwards', (tester) async {
    // `renderedPath` is read from qlevar's committed path, not from the path
    // the route was asked for, so during a redirect chain the login page can
    // be built while the navigator still reports `/` — the other half of the
    // guard. Mounting it on a delegate whose init path is the app root is
    // exactly that frame.
    final container = scaffold.makeContainerWithModules();
    addTearDown(container.dispose);
    container.read(pathForwardingProvider.notifier).forward('/login');

    await pumpLoginAt(tester, container, AppRouter.root);

    expect(QR.currentPath, FeedRouter.root);
    expect(find.text('feed page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a successful sign-in on the web page replays the forwarded '
      'path', (tester) async {
    // The button awaits the token exchange and then reads the token back: on
    // `data` it navigates to the forwarded path. Signed out, so no post-login
    // effect competes for the navigation — the button's own arm is the only
    // thing that moves the router.
    const storedRefreshToken = 'refresh-token-123';
    final jwt = _fakeJwt('user-42');
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('crossingthestreams.io/flutter_appauth'),
      (call) async {
        expect(call.method, 'authorizeAndExchangeCode');
        return <String, dynamic>{
          'accessToken': jwt,
          'refreshToken': storedRefreshToken,
        };
      },
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('crossingthestreams.io/flutter_appauth'),
        null,
      ),
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      ),
    );

    final container = scaffold.makeSignInFlowContainer(
      authRepository: AuthRepository(openIdRepository: scaffold.repository),
    );
    addTearDown(container.dispose);
    container.read(pathForwardingProvider.notifier).forward('/vote/detail');

    await pumpLoginAt(
      tester,
      container,
      '/login',
      routes: {'/vote/detail': 'vote page'},
    );
    expect(find.byType(WaitingButton), findsOneWidget);

    await tester.tap(find.byType(WaitingButton));
    await settle(tester, frames: 24);

    // The exchange really ran and the page followed the forwarded path.
    expect(container.read(authTokenProvider).value?.accessToken, jwt);
    expect(QR.currentPath, '/vote/detail');
    expect(find.text('vote page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the mobile sign-in page forwards too, marking the session as '
      'logged in', (tester) async {
    // Same effect, mobile page: reached while the navigator still reports the
    // app root, signed in, with a forwarding path that is not yet logged in.
    final container = scaffold.makeContainerWithModules();
    addTearDown(container.dispose);
    container.read(pathForwardingProvider.notifier).forward('/login');

    await pumpLoginAt(
      tester,
      container,
      AppRouter.root,
      page: () => const AppSignIn(),
    );

    expect(QR.currentPath, FeedRouter.root);
    expect(find.text('feed page'), findsOneWidget);
    expect(container.read(pathForwardingProvider).isLoggedIn, isTrue);
    expect(tester.takeException(), isNull);
  });
}

/// Builds a syntactically valid, non-expired JWT whose `sub` claim is [id].
/// The real JwtDecoder parses the payload, so both parts are proper JSON.
String _fakeJwt(String id) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'RS256', 'typ': 'JWT'})}.'
      '${part({'sub': id, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.sig';
}
