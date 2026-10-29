import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/router.dart';

import '../../shared/app_scaffold.dart';

/// LoadingPage's user-error arm — the `error: → QR.to(LoginRouter.root)`
/// branch of `user.when` in the boot screen (`lib/others/ui/loading_page.dart`),
/// reached through `failAsyncUser`: the real notifier only lands in `error:`
/// through an unstubbed usersMeGet, so no shipped fake could put it there.
/// The existing loading_page_test covers only the spinner, and `QR.to`
/// throws without a registered navigator, so this arm mounts the real
/// /loading route.
///
/// qlevar_router keeps the active route branch in process-global state and
/// only processes the init-path chain on an isolate's FIRST navigation, so
/// — like the gating files — this one owns exactly one deep link (convention
/// 19): the other three arms live in their own files.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'an unresolvable user routes from the boot screen back to the login page',
    (tester) async {
      // Version gate open and logged in, but the user load failed: the
      // error arm of user.when.
      final container = scaffold.makeContainer(failAsyncUser: true);
      addTearDown(container.dispose);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: AppRouter.loading,
        // The harness pins the session logged in, so the /login the user
        // error arm targets bounces straight on to /feed — landing there is
        // the observable trace of that arm.
        allowedModules: const {'feed'},
        pumpAndSettle: false,
      );
      // Feed is behind a deferred library: poll, a fixed settle cannot race
      // the load.
      for (
        var i = 0;
        i < 25 && find.text('No news available').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }

      // The feed it was bounced to, not `Sign in`: /login redirects a
      // signed-in session (qlevar's path can still report the asked route).
      expect(find.text('No news available'), findsOneWidget);
      expect(QR.currentPath, '/feed');
    },
  );
}
