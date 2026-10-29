import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/router.dart';

import '../../shared/app_scaffold.dart';

/// LoadingPage's outdated-app arm — the `!value → QR.to(AppRouter.update)`
/// branch of the boot screen (`lib/others/ui/loading_page.dart`). The
/// existing loading_page_test covers only the spinner: it holds the version
/// verifier precisely so NOTHING routes, and `QR.to` throws without a
/// registered navigator, so this arm mounts the real /loading route.
///
/// qlevar_router keeps the active route branch in process-global state and
/// only processes the init-path chain on an isolate's FIRST navigation, so
/// — like the gating files — this one owns exactly one deep link (convention
/// 19): the other three arms live in their own files.
const updateCopy = 'Your app version is too old.\n\nPlease update the app.';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'an app below the minimum version routes from the boot screen to the update page',
    (tester) async {
      // minimalTitanVersionCode (1000) > titanVersion (1): the !value arm.
      final container = scaffold.makeContainer(
        titanVersion: 1,
        minimalTitanVersionCode: 1000,
      );
      addTearDown(container.dispose);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: AppRouter.loading,
        pumpAndSettle: false,
      );
      // UpdatePage is behind a deferred library: poll, a fixed settle
      // cannot race the load.
      for (var i = 0; i < 25 && find.text(updateCopy).evaluate().isEmpty; i++) {
        await settle(tester, frames: 4);
      }

      expect(find.text(updateCopy), findsOneWidget);
      expect(QR.currentPath, AppRouter.update);
    },
  );
}
