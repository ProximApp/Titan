import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/router.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

import '../../shared/app_scaffold.dart';

/// LoadingPage's forwarded-path arm — the `data: → QR.to(pathForwarding.path)`
/// branch of `user.when` in the boot screen (`lib/others/ui/loading_page.dart`):
/// with a resolved user the boot screen hands off to the destination a
/// previous screen stored. The existing loading_page_test covers only the
/// spinner, and `QR.to` throws without a registered navigator, so this arm
/// mounts the real /loading route.
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
    'the boot screen forwards to the stored destination once the user loads',
    (tester) async {
      final container = scaffold.makeContainer(
        seedAsyncUser: true,
        user: CoreUser.empty(),
      );
      addTearDown(container.dispose);
      // The destination a previous screen stored (here: settings), which the
      // data arm of user.when forwards to.
      container.read(pathForwardingProvider.notifier).forward('/settings');

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: AppRouter.loading,
        // The boot screen forwards to the destination this test stored, so
        // the settings page is the subject, not a foreign leak.
        allowedModules: const {'settings'},
        pumpAndSettle: false,
      );
      // Settings is behind a deferred library: poll, a fixed settle cannot
      // race the load.
      for (var i = 0; i < 25 && find.text('Account').evaluate().isEmpty; i++) {
        await settle(tester, frames: 4);
      }

      expect(find.text('Account'), findsOneWidget);
      expect(QR.currentPath, '/settings');
    },
  );
}
