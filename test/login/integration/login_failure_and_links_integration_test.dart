import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncError, AsyncLoading;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/auth/providers/openid_provider.dart';

import '../../shared/app_scaffold.dart';

/// The failure side of the sign-in form and the two external links, neither
/// of which any existing login test touches: a rejected code exchange has to
/// land `authTokenProvider` in its error state WITHOUT leaving /login (the
/// `.when(error:)` arm of the sign-in button), and the register / recover
/// links go through `launchUrl`, which the real plugin only answers on a
/// device.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  const appAuthChannel = MethodChannel('crossingthestreams.io/flutter_appauth');
  const urlChannel = MethodChannel('plugins.flutter.io/url_launcher');

  /// The shell answers every code exchange with an empty reply, which the
  /// repository reads as `Exception('Wrong credentials')`.
  void stubFailingShell() {
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      appAuthChannel,
      (call) async => <String, dynamic>{},
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        appAuthChannel,
        null,
      ),
    );
  }

  testWidgets('a rejected sign-in fails in place instead of navigating', (
    tester,
  ) async {
    // The REAL OpenIdTokenProvider (the logged-out container's fake only
    // overrides build), so its catch arm is what records the failure.
    final container = scaffold.makeLoggedOutContainer(
      authRepository: AuthRepository(openIdRepository: scaffold.repository),
    );
    addTearDown(container.dispose);
    stubFailingShell();

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/login',
      pumpAndSettle: false,
    );
    await settle(tester);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await settle(tester, frames: 20);

    // The provider took the error arm and the user is still on the form —
    // no toast text is visible in this harness (convention 25), so the
    // provider state and the path are the assertions.
    expect(container.read(authTokenProvider), isA<AsyncError<dynamic>>());
    expect(find.text('Sign in'), findsOneWidget);
    // The failure toast is armed with an auto-close timer: unmount the tree
    // and pump the toast out (convention 21), or the binding reports a
    // pending Timer after the test.
    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });

  testWidgets('a sign-in that never answers keeps the button on loading', (
    tester,
  ) async {
    // `app_sign_in.dart:146` is the button's `loading: () {}` arm: the form
    // only takes it while an exchange is in flight, so the shell answers with
    // a future that never completes. The arm itself is dark in lcov (an empty
    // closure has no instructions); this test is what pins the state that
    // selects it.
    final container = scaffold.makeLoggedOutContainer(
      authRepository: AuthRepository(openIdRepository: scaffold.repository),
    );
    addTearDown(container.dispose);

    final pending = Completer<Map<String, dynamic>?>();
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      appAuthChannel,
      (call) => pending.future,
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        appAuthChannel,
        null,
      ),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/login',
      pumpAndSettle: false,
    );

    // Let the entry animation finish: the template's callback (line 79)
    // reverses it once it is complete, which only happens if the suite pumps
    // past its full duration.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Sign in'));
    await settle(tester, frames: 6);

    expect(container.read(authTokenProvider), isA<AsyncLoading<dynamic>>());
    expect(find.text('Sign in'), findsOneWidget);

    // Let the exchange collapse before unmounting: the button's builder reads
    // `ref` after its await, which is illegal once the tree is gone.
    pending.complete(null);
    await settle(tester, frames: 10);
    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });

  testWidgets('the register and recover links open their calypsso URLs', (
    tester,
  ) async {
    final container = scaffold.makeLoggedOutContainer();
    addTearDown(container.dispose);

    final launched = <String>[];
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(urlChannel, (
      call,
    ) async {
      if (call.method == 'launch') {
        final args = Map<String, Object?>.from(call.arguments as Map);
        launched.add(args['url'] as String);
        return true;
      }
      return false;
    });
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        urlChannel,
        null,
      ),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/login',
      pumpAndSettle: false,
    );
    await settle(tester);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Create an account'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Forgot password?'));
    await settle(tester, frames: 6);

    expect(launched, hasLength(2));
    expect(launched.first, endsWith('/calypsso/register'));
    expect(launched.last, endsWith('/calypsso/recover'));
  });

  testWidgets('the sign-in screen collects no password of its own', (
    tester,
  ) async {
    // Bug report 12/10: "l'app lui dit que le mot de passe est incorrect, mais
    // la réinitialisation dit que son compte n'existe pas". The app cannot be
    // the one saying it: authentication happens on Calypsso's page (opened
    // through the shell on mobile, in a popup on web), and this screen has
    // exactly one control — the Sign in button — plus the two links. What the
    // app ever reports is `loginLoginFailed`, and this test keeps it that way:
    // if a password field or a credential claim appears here, the report's
    // attribution changes and this fails.
    final container = scaffold.makeLoggedOutContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/login',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.textContaining('Wrong'), findsNothing);
    expect(find.textContaining('Incorrect'), findsNothing);
    expect(find.textContaining('does not exist'), findsNothing);
  });
}
