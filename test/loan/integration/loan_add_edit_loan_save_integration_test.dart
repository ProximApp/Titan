import 'package:flutter/material.dart' show TextFormField;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/adapters/item.dart';
import 'package:titan/loan/providers/borrower_provider.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/loan_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/loan_group_page/add_edit_loan_page.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The success paths of `AddEditButton`, which the guard-branch widget test
/// never reaches: with a selected item, a borrower and a valid date range
/// the tap builds the `Loan` and round-trips it — POST in create mode, PATCH
/// in edit mode — then pops back to the admin page.
void main() {
  late IntegrationScaffold scaffold;

  final loaner = loanerFixture(
    id: 'loaner-1',
    name: 'Asso Matériel',
    groupManagerId: 'grp-1',
  );
  final tente = itemFixture(
    id: 'item-1',
    name: 'Tente 2 places',
    totalQuantity: 4,
    loanedQuantity: 1,
    suggestedCaution: 3000,
    suggestedLendingDuration: 3,
  );

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Boots the add/edit-loan form with the stubs every save needs. [seedLoan]
  /// puts the page in edit mode; the date range and the borrower are seeded
  /// the way the admin page's onEdit handler does it (it is not run on a
  /// deep link).
  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    Loan? seedLoan,
  }) async {
    // Convention 20: the harness font wraps the admin strip's LoanCard text
    // inside its pinned 250x170 box; the bundled faces are the ones the
    // layout is designed for.
    await loadAppFonts();
    final container = scaffold.makeContainer(myLoaners: [loaner]);
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.loansUsersMeLoanersGet())
        .thenAnswer((_) async => chopperListResponse([loaner]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse([tente]));
    // The ongoing strip asks WITHOUT the `returned` flag; the list has to
    // actually contain the loan or ListNotifierAPI.update refuses the PATCH
    // as a mutation of a list it never loaded (value == false → error toast,
    // no QR.back).
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer(
      (_) async => chopperListResponse(<Loan>[if (seedLoan != null) seedLoan]),
    );
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
        returned: true,
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));

    container.read(loanerIdProvider.notifier).setId('loaner-1');
    if (seedLoan != null) {
      container.read(loanProvider.notifier).setLoan(seedLoan);
    }
    container
        .read(borrowerProvider.notifier)
        .setBorrower(seedLoan?.borrower ?? coreUserSimpleFixture());
    container.read(startProvider.notifier).setStart('1/15/2026');
    container.read(endProvider.notifier).setEnd('1/18/2026');

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditLoan}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);
    return container;
  }

  /// Selects the strip's single item (the only plus icon on the page) and
  /// fills the one field the form's validator refuses to leave empty.
  Future<void> prepareAndSave(WidgetTester tester) async {
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
    );
    await settle(tester, frames: 6);

    // The borrower entry is the FIRST form field on the page (the item
    // strip's search bar is a plain TextField; the date entries follow the
    // borrower in tree order).
    final borrowerField = find.descendant(
      of: find.byType(AddEditLoanPage),
      matching: find.byType(TextFormField),
    );
    expect(borrowerField, findsWidgets);
    await tester.enterText(borrowerField.first, 'Jane Doe');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
  }

  testWidgets('a valid new loan round-trips through POST', (tester) async {
    await pumpForm(tester);
    expect(find.text('Add a loan'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    var posts = 0;
    LoanCreation? sent;
    when(() => scaffold.repository.loansPost(body: any(named: 'body')))
        .thenAnswer((inv) async {
          posts++;
          sent = inv.namedArguments[#body] as LoanCreation;
          return chopperResponse(loanFixture(id: 'l-new'));
        });

    await prepareAndSave(tester);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 40);

    expect(posts, 1);
    expect(sent!.borrowerId, coreUserSimpleFixture().id);
    expect(sent!.itemsBorrowed, hasLength(1));
    expect(sent!.itemsBorrowed.single.itemId, 'item-1');
    expect(sent!.start, DateTime(2026, 1, 15));
    expect(sent!.end, DateTime(2026, 1, 18));
    // QR.back() popped the form.
    expect(find.text('Add a loan'), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('a valid edited loan round-trips through PATCH', (tester) async {
    final loan = loanFixture(
      id: 'l-1',
      borrower: coreUserSimpleFixture(
        id: 'u-1',
        firstname: 'Jane',
        name: 'Doe',
      ),
      loaner: loaner,
      itemsQty: [ItemQuantity(itemSimple: tente.toItemSimple(), quantity: 1)],
    );
    await pumpForm(tester, seedLoan: loan);
    expect(find.text('Edit the loan'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    var patches = 0;
    LoanUpdate? sent;
    when(
      () => scaffold.repository.loansLoanIdPatch(
        loanId: any(named: 'loanId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      patches++;
      expect(inv.namedArguments[#loanId], 'l-1');
      sent = inv.namedArguments[#body] as LoanUpdate;
      return chopperResponse(loan);
    });

    await prepareAndSave(tester);
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 40);

    expect(patches, 1);
    expect(sent!.borrowerId, 'u-1');
    // QR.back() popped the form.
    expect(find.text('Edit the loan'), findsNothing);
    await scaffold.drainToast(tester);
  });
}
