import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/ui/pages/main_page/main_page.dart';
import 'package:titan/router.dart';

import '../shared/app_scaffold.dart';

/// The app's end-to-end journey, in the sense this repo means it: the REAL
/// route table, the REAL middlewares, the real deferred page loading and the
/// real shell — one cold start, then navigation the way a reader does it, from
/// the navbar rather than from a deep link.
///
/// Everything else in `test/` is scoped to one module, because a module test
/// should fail when that module breaks. This file is the opposite trade: it
/// crosses modules on purpose, so a break in the seam between them (the boot
/// gate, the shell, the navbar's module list) fails here even though every
/// module's own tests stay green.
///
/// `allowedModules` is how convention 30 is satisfied — the guard fails on any
/// page a module other than the one under test owns, and here there is
/// deliberately more than one:
///   * `feed` — the route `/` lands on once the session is accepted;
///   * `loan` — the module the navbar entry opens.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  CorePermission loanAccess() => CorePermission(
    permissionName: 'loan.access',
    groups: const [],
    accountTypes: const [enums.AccountType.student],
  );

  testWidgets('a signed-in reader boots into the feed and opens a module', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        id: 'user-1',
        accountType: enums.AccountType.student,
      ),
      seedAsyncUser: true,
      permissions: [loanAccess()],
      permissionCatalog: const ['loan.access'],
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: AppRouter.root,
      allowedModules: const {
        'feed', // the page `/` resolves to
        'loan', // the module the navbar opens below
      },
      pumpAndSettle: false,
    );

    // Cold start: `/` is authenticated and its page is a deferred library, so
    // poll for the feed rather than trusting a frame count.
    for (
      var i = 0;
      i < 40 && find.text('No news available').evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }
    expect(find.text('No news available'), findsOneWidget);

    // The shell is up: the navbar entry for the module this reader was
    // granted is there, and one they were not granted is not.
    // The navbar labels are the module names from the l10n bundle, not the
    // route roots: "Loan" is `/loan`, "Vote" is `/vote`.
    expect(find.text('Loan'), findsOneWidget);
    expect(find.text('Vote'), findsNothing);

    // Open it the way a reader does — the navbar, not a deep link.
    await tester.tap(find.text('Loan'));
    for (
      var i = 0;
      i < 40 && find.byType(LoanMainPage).evaluate().isEmpty;
      i++
    ) {
      await settle(tester, frames: 4);
    }

    expect(find.byType(LoanMainPage), findsOneWidget);
    expect(find.text('Loan'), findsOneWidget, reason: 'navbar persists');

    expect(tester.takeException(), isNull);
  });
}
