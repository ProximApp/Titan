import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/login/router.dart';
import 'package:titan/login/ui/app_sign_in.dart';
import 'package:titan/router.dart';

import '../../shared/app_scaffold.dart';

/// LoadingPage's `!isLoggedIn` arm — the one branch of the boot screen that no
/// test had ever entered.
///
/// Every other arm lives in its own file (the version gate, the update route,
/// the offline route, the user-error route), and all of them run in a session
/// the harness pins LOGGED IN. This is the fourth case: the backend answered,
/// the client is current, and there is no session — the boot screen has to
/// reach the sign-in page instead of forwarding anywhere.
///
/// Convention 19: qlevar keeps its active branch in process-global state and
/// only processes the init-path chain on an isolate's first navigation, so
/// this file owns exactly one deep link.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a boot with no session lands on the sign-in page', (
    tester,
  ) async {
    final container = scaffold.makeLoggedOutContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: AppRouter.loading,
      pumpAndSettle: false,
    );

    // The sign-in page is behind a deferred library: poll for it rather than
    // guessing a frame count.
    for (var i = 0; i < 25 && find.byType(AppSignIn).evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }

    expect(QR.currentPath, LoginRouter.root);
    expect(find.byType(AppSignIn), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
