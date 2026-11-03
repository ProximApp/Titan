import 'package:flutter/material.dart' show TextField, TextFormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/borrower_provider.dart';
import 'package:titan/loan/providers/edit_selected_items_provider.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/loan_group_page/add_edit_loan_page.dart';
import 'package:titan/loan/ui/pages/loan_group_page/search_result.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/user/providers/user_list_provider.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The parts of the add-loan form its save test never touches: the item
/// search going back to empty (which must restore the unfiltered strip, not
/// leave the filtered one behind), picking a borrower out of the suggestion
/// list, and a refused POST.
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

  Future<ProviderContainer> pumpForm(WidgetTester tester) async {
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
    ).thenAnswer((_) async => chopperListResponse([tente]));
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
    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditLoan}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
    return container;
  }

  Finder itemSearch() => find.byType(TextField).first;

  Finder borrowerField() => find
      .descendant(
        of: find.byType(AddEditLoanPage),
        matching: find.byType(TextFormField),
      )
      .first;

  testWidgets('clearing the item search restores the full strip', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);

    await tester.enterText(itemSearch(), 'Tente');
    await settle(tester, frames: 6);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);

    // Emptying the bar falls back to the unfiltered item list rather than
    // leaving the last filtered answer on screen.
    await tester.enterText(itemSearch(), '');
    await settle(tester, frames: 6);
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    expect(find.textContaining('3 Available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a suggestion fills the borrower and folds the list', (
    tester,
  ) async {
    final container = await pumpForm(tester);

    // The suggestion list renders whatever the user search last answered;
    // seed it rather than driving the search endpoint.
    container.read(userList.notifier).state = AsyncValue.data([
      coreUserSimpleFixture(id: 'u-9', firstname: 'Jane', name: 'Doe'),
    ]);
    await settle(tester, frames: 6);
    expect(find.byType(SearchResult), findsOneWidget);

    final suggestion = find.descendant(
      of: find.byType(SearchResult),
      matching: find.text('Jane Doe'),
    );
    expect(suggestion, findsOneWidget);
    await tester.ensureVisible(suggestion);
    await tester.tap(suggestion);
    await settle(tester, frames: 6);

    expect(container.read(borrowerProvider).id, 'u-9');
    expect(
      tester.widget<TextFormField>(borrowerField()).controller?.text,
      'Jane Doe',
    );
    expect(container.read(userList).value, isEmpty);
  });

  testWidgets('a refused creation reports the adding error', (tester) async {
    final container = await pumpForm(tester);
    container
        .read(borrowerProvider.notifier)
        .setBorrower(coreUserSimpleFixture(id: 'u-1'));
    // The button parses both dates before it sends; a deep link leaves them
    // empty, so seed the range the admin's onEdit handler would.
    container.read(startProvider.notifier).setStart('1/15/2026');
    container.read(endProvider.notifier).setEnd('1/18/2026');
    // The form's validator reads the FIELD, not the borrower provider, so the
    // text has to be there too or the button stops before the request.
    await tester.enterText(borrowerField(), 'Jane Doe');
    await settle(tester, frames: 6);

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
    );
    await settle(tester, frames: 6);
    expect(container.read(editSelectedListProvider), [1]);

    var posts = 0;
    when(() => scaffold.repository.loansPost(body: any(named: 'body')))
        .thenAnswer((_) async {
          posts++;
          // A refusal surfaces as a throw from the repository; the notifier
          // turns it into `false`, which is what the button reports.
          throw Exception('refused');
        });

    await tester.tap(find.text('Add'));
    await settle(tester, frames: 20);

    expect(posts, 1);
    expect(find.text('Error while adding'), findsOneWidget);
    // The form stays up so the user can retry.
    expect(find.text('Add a loan'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('clearing the borrower field drops the suggestions', (
    tester,
  ) async {
    final container = await pumpForm(tester);
    final jane = coreUserSimpleFixture(
      id: 'u-9',
      firstname: 'Jane',
      name: 'Doe',
    );
    when(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query'),
        includedAccountTypes: any(named: 'includedAccountTypes'),
        excludedAccountTypes: any(named: 'excludedAccountTypes'),
        includedGroups: any(named: 'includedGroups'),
        excludedGroups: any(named: 'excludedGroups'),
      ),
    ).thenAnswer((_) async => chopperListResponse([jane]));

    await tester.enterText(borrowerField(), 'Ja');
    await settle(tester, frames: 6);
    expect(container.read(userList).value, [jane]);

    // Emptying the field clears the suggestion list instead of leaving the
    // last answer dangling under the form.
    await tester.enterText(borrowerField(), '');
    await settle(tester, frames: 6);
    expect(container.read(userList).value, isEmpty);
    expect(find.byType(SearchResult), findsOneWidget);
  });
}
