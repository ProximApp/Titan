import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/router.dart';

import '../../shared/app_scaffold.dart';

/// The loan admin gate derives from the user's loaner list: a non-empty
/// list means admin. Pre-seeding the provider is the same async-gate trap
/// as the mypayment/booking gates.
void main() {
  late IntegrationScaffold scaffold;

  final loaner = Loaner.empty().copyWith(
    id: 'loaner-1',
    name: 'Asso Matériel',
    groupManagerId: 'grp-1',
  );
  final item = Item.empty().copyWith(
    id: 'item-1',
    name: 'Tente 2 places',
    loanerId: 'loaner-1',
    totalQuantity: 4,
    loanedQuantity: 1,
    suggestedCaution: 3000,
    suggestedLendingDuration: 3,
  );

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /loan/admin lists the loaner items for a loaner manager',
    (tester) async {
      final container = scaffold.makeContainer(myLoaners: [loaner]);
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(
        () => scaffold.repository.loansUsersMeLoanersGet(),
      ).thenAnswer((_) async => chopperListResponse([loaner]));
      when(
        () => scaffold.repository.loansLoanersLoanerIdItemsGet(
          loanerId: 'loaner-1',
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
        initialPath: '${LoanRouter.root}${LoanRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The item card renders with the real item data from the endpoint.
      expect(find.textContaining('Tente 2 places'), findsOneWidget);
    },
  );
}
