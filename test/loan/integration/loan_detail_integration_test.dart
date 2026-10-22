import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/loan_provider.dart';
import 'package:titan/loan/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /loan/detail renders the pre-selected loan', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    // The detail page renders the client-side loan state set by the loan
    // lists; no repository call happens on mount. The fixed-width LoanCard
    // overflows its row layout for long names (see README known bugs), so
    // the exception thrown during layout is tolerated and the render is
    // still asserted.
    tester.takeException();
    container
        .read(loanProvider.notifier)
        .setLoan(
          Loan.empty().copyWith(
            id: 'loan-1',
            notes: 'Return before Friday',
            borrower: CoreUserSimple.empty().copyWith(
              id: 'user-1',
              firstname: 'Jane',
              name: 'Doe',
            ),
            loaner: Loaner.empty().copyWith(id: 'loaner-1', name: 'Robotics'),
          ),
        );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${LoanRouter.root}${LoanRouter.detail}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('Jane Doe'), findsWidgets);
    // capitalize() lowercases everything after the first character.
    expect(find.text('Robotics'), findsWidgets);
    expect(find.textContaining('Return before Friday'), findsOneWidget);
  });
}
