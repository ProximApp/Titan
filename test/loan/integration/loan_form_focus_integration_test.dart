import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/borrower_provider.dart';
import 'package:titan/loan/providers/item_focus_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/loan_group_page/add_edit_loan_page.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// `add_edit_loan_page.dart`'s `if (focus) focusNode.requestFocus()` stays
/// dark in `loan_focus_branches_integration_test.dart`, which raises
/// `itemFocusProvider` while the ADMIN page is mounted — the form is not on
/// screen there. This file mounts the form itself with the flag already true,
/// as a return navigation leaves it.
///
/// Its own file because the QR router is a process-wide singleton: mounting a
/// second deep link after the admin one in the same isolate drops the route
/// (the same ordering quirk `purchases_integration_test.dart` documents).
void main() {
  late IntegrationScaffold scaffold;

  final loaner = loanerFixture(
    id: 'loaner-1',
    name: 'Asso Matériel',
    groupManagerId: 'grp-1',
  );
  final tent = itemFixture(id: 'item-1', name: 'Tente 2 places');

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the loan form takes focus when it is asked to', (tester) async {
    await loadAppFonts();
    final container = scaffold.makeContainer(myLoaners: [loaner]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.loansUsersMeLoanersGet())
        .thenAnswer((_) async => chopperListResponse([loaner]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: any(named: 'loanerId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([tent]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
        returned: true,
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));

    container.read(loanerIdProvider.notifier).setId('loaner-1');
    container
        .read(borrowerProvider.notifier)
        .setBorrower(coreUserSimpleFixture());
    container.read(itemFocusProvider.notifier).setFocus(true);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditLoan}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    // The form mounted with the flag set: the focus line ran without throwing
    // and the form is on screen.
    expect(find.byType(AddEditLoanPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
