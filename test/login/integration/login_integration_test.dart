import 'package:flutter_test/flutter_test.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/login/ui/components/sign_in_up_bar.dart';

import '../../shared/app_scaffold.dart';

/// Arms of the login screen this file CANNOT reach, kept honest here rather
/// than faked:
///  - `router.dart`'s two `kIsWeb && ...` branches: a host test never runs on
///    web, so the web sign-in page and its deferred library are unreachable —
///    `login_web_panels_widget_test.dart` mounts those widgets directly
///    instead of pretending the route took them;
///  - `app_sign_in.dart`'s `renderedPath != root && != AppRouter.root` early
///    return, which needs the navigator to have SHOWN another path and then
///    come back to `/login` — qlevar runs one deep link per isolate
///    (convention 19), so no single-link test can produce that history;
///  - `controller.reverse()` in the template callback and the empty
///    `loading: () {}` arm of the token `.when`: both fire only mid-transition
///    (intro finished, token still in flight), which the shell's fakes settle
///    past;
///  - `background_painter.dart`'s `points.length < 3` guard: the painter's own
///    point lists are literals of four or more.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    QR.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'boot while signed out lands on the login page with its actions',
    (tester) async {
      final scaffold = IntegrationScaffold();
      scaffold.stubInformation();
      final container = scaffold.makeLoggedOutContainer();
      addTearDown(container.dispose);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/login',
        pumpAndSettle: false,
      );
      await settle(tester);

      expect(find.text('MyEMApp'), findsWidgets);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    },
  );

  testWidgets('a failed loading check leaves the sign-in button usable', (
    tester,
  ) async {
    // `loadingProvider.maybeWhen(data: ..., orElse: isWaitingForData)` — the
    // orElse arm is what answers when the check itself fails, and a user who
    // cannot be told apart from a reloading one would be stuck with a spinner
    // they can never clear. Mounted signed out, so `isWaitingForData` is false
    // and the button is live.
    final scaffold = IntegrationScaffold();
    scaffold.stubInformation();
    final container = scaffold.makeLoggedOutContainer(
      providerOverrides: [
        loadingProvider.overrideWith(
          (ref) async => throw StateError('no auth'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/login',
      pumpAndSettle: false,
    );
    await settle(tester);
    // Let the failing future land and the page rebuild.
    await settle(tester, frames: 6);

    expect(find.text('Sign in'), findsOneWidget);
    expect(
      tester.widget<SignInUpBar>(find.byType(SignInUpBar)).isLoading,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
