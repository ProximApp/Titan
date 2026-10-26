import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncError;
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
}
