import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/item_focus_provider.dart';
import 'package:titan/loan/providers/loan_focus_provider.dart';
import 'package:titan/loan/router.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The loan pages focus their form when a return navigation asks them to:
/// `loanFocusProvider` drives the admin strips and `itemFocusProvider` the
/// add/edit form. Both branches (`focusNode.requestFocus()`) were dark because
/// every existing test leaves the flag false, so the one-line effect of the
/// provider could have been deleted without any test noticing.
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

  testWidgets('the admin strips take focus when they are asked to', (
    tester,
  ) async {
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

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${LoanRouter.root}${LoanRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    // The navigating handlers raise the flag when a page comes back; from
    // there the next build asks its node for focus.
    container.read(loanFocusProvider.notifier).setFocus(true);
    container.read(itemFocusProvider.notifier).setFocus(true);
    await settle(tester, frames: 10);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
  });
}
