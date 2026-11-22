import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/home/router.dart';
import 'package:titan/home/ui/home.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/others/ui/no_internet_page.dart';
import 'package:titan/router.dart';

import '../../shared/app_scaffold.dart';

/// The one arm of NoInternetPage that needs a router: the retry button asks the
/// verifier again, and when the answer finally arrives it forwards to `/home`.
///
/// `no_internet_page_widget_test.dart` covers the page itself and the "still
/// offline" half of that button by mounting it routerless; this file gives it a
/// real route table and the `noInternetRecovers` scenario, whose first retry
/// succeeds. Two lines of the button — the post-frame `QR.to(HomeRouter.root)`
/// — only exist on this side of the branch.
///
/// Convention 19: one deep link per file.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a retry that reconnects moves the user on to home', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      scenario: BootScenario.noInternetRecovers,
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: AppRouter.noInternet,
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    expect(find.byType(NoInternetPage), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(NoInternetPage)),
    )!;

    await tester.tap(find.text(l10n.othersRetry));
    // Home is behind a deferred library: poll for the page rather than guess.
    for (var i = 0; i < 25 && find.byType(HomePage).evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }

    expect(QR.currentPath, HomeRouter.root);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NoInternetPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
