import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/router.dart';

import '../../shared/app_scaffold.dart';

/// LoadingPage's offline arm — the `error: → QR.to(AppRouter.noInternet)`
/// branch of the boot screen (`lib/others/ui/loading_page.dart`), reached
/// through `failVersionVerifier` (ledger #55's error arm). The existing
/// loading_page_test covers only the spinner, and `QR.to` throws without a
/// registered navigator, so this arm mounts the real /loading route.
///
/// qlevar_router keeps the active route branch in process-global state and
/// only processes the init-path chain on an isolate's FIRST navigation, so
/// — like the gating files — this one owns exactly one deep link (convention
/// 19): the other three arms live in their own files. NoInternetPage is in
/// lib/others — the module under test — so no allowedModules is needed.
const noInternetCopy = 'Please check your internet connection';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'a failed version check routes from the boot screen to the no-internet page',
    (tester) async {
      final container = scaffold.makeContainer(failVersionVerifier: true);
      addTearDown(container.dispose);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: AppRouter.loading,
        pumpAndSettle: false,
      );
      // NoInternetPage is behind a deferred library: poll, a fixed settle
      // cannot race the load.
      for (
        var i = 0;
        i < 25 && find.text(noInternetCopy).evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }

      expect(find.text(noInternetCopy), findsOneWidget);
      expect(QR.currentPath, AppRouter.noInternet);
    },
  );
}
