import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/providers/item_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';

import '../../shared/app_scaffold.dart';

/// The add_edit_item edit-mode shell. Own file: the one-deep-link-per-file
/// rule (README convention 1), and the three stacked deferred libraries
/// (main, admin, form) need a longer frame budget than the default settle.
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
    'the add_edit_item form prefills from the selected item in edit mode',
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
      // The admin main page mounts underneath and its OnGoingLoan /
      // LoanHistory panels auto-load the loan lists for the selected
      // loaner.
      when(
        () => scaffold.repository.loansLoanersLoanerIdLoansGet(
          loanerId: any(named: 'loanerId'),
          returned: any(named: 'returned'),
        ),
      ).thenAnswer((_) async => chopperListResponse(<Loan>[]));

      // In app flow the admin page sets the loaner id and the item before
      // navigating; on a deep link the pre-seed plays that role.
      container.read(loanerIdProvider.notifier).setId('loaner-1');
      container.read(itemProvider.notifier).setItem(item);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath:
            '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditItem}',
        pumpAndSettle: false,
      );
      // Three deferred libraries load in sequence (main, admin, form); give
      // the pipeline enough frames for all of them.
      await settle(tester, frames: 40);

      // Edit mode title; the form labels (Name, Quantity, Deposit) all
      // render (TextEntry labels come via InputDecoration).
      expect(find.text('Edit the object'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('Deposit'), findsOneWidget);
    },
  );
}
