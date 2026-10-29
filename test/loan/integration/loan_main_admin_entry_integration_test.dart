import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/router.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The admin entry point on the loan main page: the `AdminButton` only
/// renders for a user with loaners (the same provider that gates
/// `/loan/admin`), and its tap is the only way to reach the admin page from
/// the main page. It lives in its own file because it is a navigation
/// journey (conventions 2/10/19): the populated-main-page file already
/// spends its deep link and its mid-test route on the detail page.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the admin button routes to the loan admin page', (tester) async {
    final loaner = loanerFixture(
      id: 'loaner-1',
      name: 'Asso Matériel',
      groupManagerId: 'grp-1',
    );
    final item = itemFixture(
      id: 'item-1',
      name: 'Tente 2 places',
      loanerId: 'loaner-1',
    );

    final container = scaffold.makeContainer(myLoaners: [loaner]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.loansUsersMeGet())
        .thenAnswer((_) async => chopperListResponse(<Loan>[]));
    when(() => scaffold.repository.loansUsersMeLoanersGet())
        .thenAnswer((_) async => chopperListResponse([loaner]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: any(named: 'loanerId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([item]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: any(named: 'loanerId'),
        returned: any(named: 'returned'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: LoanRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('Admin'), findsOneWidget);

    await tester.tap(find.text('Admin'));
    await settle(tester, frames: 60);

    // The admin page mounted underneath the same shell and rendered the
    // selected loaner's item list.
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
  });
}
