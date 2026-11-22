import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/tools/providers/path_forwarding_provider.dart';

import '../../shared/app_scaffold.dart';

/// Builds a syntactically valid, non-expired JWT whose `sub` claim is [id].
/// The real JwtDecoder parses the payload, so `isLoggedInProvider` derives
/// "signed in" from the token itself rather than from a pinned boolean.
String fakeJwt(String id) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'RS256', 'typ': 'JWT'})}.'
      '${part({'sub': id, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.sig';
}

/// The session LIFECYCLE — the one thing the sign-in and logout tests each
/// pin only one half of.
///
/// `login_sign_in_flow_integration_test` proves a code exchange produces a
/// session; `settings_logout_integration_test` proves the settings row ends
/// it. Neither watches the app's own derivation flip, because both pin or
/// bypass `isLoggedInProvider`: one starts signed out, the other pins true
/// for the whole test. So the state that protects every route —
/// `IsLoggedInProvider` reading the stored token — was never observed going
/// from true to false, and a sign-out that cleared the toast but not the
/// session would still pass both.
///
/// These tests therefore start from a REAL valid session (no `isLoggedIn`
/// override anywhere) and assert what the navigation layer then does with it.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// `AuthRepository.deleteToken()` reaches `flutter_secure_storage`'s channel
  /// and `CacheManager`'s real IO; stubbing the channel keeps the deletion
  /// real-but-hermetic and records which keys it asked for, so the test can
  /// prove the stored refresh token was actually removed.
  List<String> stubSecureStorageDeletion(WidgetTester tester) {
    final binding = tester.binding.defaultBinaryMessenger;
    final deleted = <String>[];
    binding.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        if (call.method == 'delete') {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          deleted.add(args['key'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => binding.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      ),
    );
    return deleted;
  }

  ProviderContainer signedInContainer() {
    final container = scaffold.makeSignInFlowContainer(
      // The REAL repository: `deleteToken` runs the genuine code path.
      authRepository: AuthRepository(openIdRepository: scaffold.repository),
      signedInToken: models.TokenResponse(
        accessToken: fakeJwt('user-42'),
        refreshToken: 'refresh-token-123',
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('a valid stored session opens a protected route', (tester) async {
    scaffold.setWideSurface(tester);
    scaffold.stubProfilePicture();
    final container = signedInContainer();

    // The derivation is not pinned: it reads the token this container seeded.
    expect(container.read(isLoggedInProvider), isTrue);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets',
      // The subject is the GUARD, not the ticket page: the point is that a
      // route owned by another module is reachable while signed in and is
      // bounced once the session ends, so landing on tickets is the expected
      // outcome of this file rather than a leak from a neighbour.
      allowedModules: {'tickets'},
    );
    await settle(tester, frames: 8);

    // The guard let the deep link through instead of bouncing to /login.
    expect(QR.currentPath, '/tickets');
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('signing out clears the session and bounces a protected route '
      'back to the login page', (tester) async {
    scaffold.setWideSurface(tester);
    scaffold.stubProfilePicture();
    final container = signedInContainer();
    final deletedKeys = stubSecureStorageDeletion(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets',
      // Same reason as the first test: a protected foreign-module route is
      // the vehicle, the session derivation is the subject.
      allowedModules: {'tickets'},
    );
    await settle(tester, frames: 8);
    expect(QR.currentPath, '/tickets');
    expect(container.read(isLoggedInProvider), isTrue);

    // Exactly what the settings row and the quit dialog run. The
    // `pathForwardingProvider` reset is part of that sequence, not a
    // convenience: the guard exempts /login only while the forwarding state
    // still believes it is signed out, so deleting the token alone leaves the
    // login route redirecting to itself.
    await container.read(authTokenProvider.notifier).deleteToken();
    container.read(pathForwardingProvider.notifier).reset();
    await settle(tester, frames: 4);

    // The session is gone in both places that matter: the token state the
    // whole app reads, and the storage that would restore it on relaunch.
    expect(
      container.read(authTokenProvider),
      isA<AsyncError<models.TokenResponse>>(),
    );
    expect(
      deletedKeys,
      contains('my_ecl_auth_token'),
      reason: 'the stored refresh token must not survive the sign-out',
    );
    expect(
      container.read(isLoggedInProvider),
      isFalse,
      reason:
          'this is the derivation the middlewares gate on — a sign-out that '
          'left it true would keep every protected route open',
    );

    // Navigating to a protected route now does what a cold signed-out start
    // does: the guard sends the user to /login. A DIFFERENT path than the one
    // on screen, because qlevar skips navigation to the current path and the
    // guard would then never run.
    QR.to('/feed');
    // The login page is a DEFERRED import, so the redirect has to be followed
    // by enough frames for the library load and the route to land.
    await settle(tester, frames: 20);

    expect(
      QR.currentPath,
      '/login',
      reason: 'the guard must answer a protected route with the login route',
    );
    // The path is the assertion, not the rendered form: the login page is a
    // deferred import that does not resolve inside this fake-async window (it
    // mounts fine on a first-frame /login boot, which is
    // login_integration_test.dart's subject), and qlevar keeps the outgoing
    // page in the tree, so "the tickets page is gone" is not observable.
    expect(QR.currentPath, isNot('/feed'));
  });
}
