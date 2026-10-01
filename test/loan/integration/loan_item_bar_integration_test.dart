import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/caution_provider.dart';
import 'package:titan/loan/providers/edit_selected_items_provider.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/loan_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// ItemBar — the add-edit-loan page's item selection strip (96 uncovered
/// lines): the per-loaner item map, the quantity steppers and their
/// end-date/caution side effects. The map is only populated through the
/// search bar's onChanged (nothing loads it on mount — a fresh page shows
/// "No items" until the user types), so every flow here drives the real
/// search field. The steppers call setEndFromSelected, which parses the
/// start date — an empty start (the shipped default) throws inside
/// DateFormat.parse (README ledger #34), so the stepper tests pre-seed
/// startProvider, the state after a legit date pick.
///
/// loan_admin_integration_test covers the admin shell render — nothing
/// overlaps. The steppers' plus icon is the only one on the page.
Loaner loaner(String id, String name) =>
    Loaner.empty().copyWith(id: id, name: name, groupManagerId: 'grp-1');

Item item(String id, String name, int total, int loaned) =>
    Item.empty().copyWith(
      id: id,
      name: name,
      loanerId: 'loaner-1',
      totalQuantity: total,
      loanedQuantity: loaned,
      suggestedCaution: 3000,
      suggestedLendingDuration: 3,
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpAddEditLoan(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    scaffold.absorbLayoutOverflows(tester);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditLoan}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);
  }

  /// Types into the page's search bar, whose onChanged populates the
  /// per-loaner item map the ItemBar renders.
  Future<void> searchItems(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField).first, query);
    await settle(tester, frames: 6);
  }

  testWidgets('the item bar appears after a search and the steppers drive '
      'end date and caution', (tester) async {
    final loaner1 = loaner('loaner-1', 'Asso Matériel');
    final tente = item('item-1', 'Tente 2 places', 4, 1);
    final container = scaffold.makeContainer(myLoaners: [loaner1]);
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.loansUsersMeLoanersGet(),
    ).thenAnswer((_) async => chopperListResponse([loaner1]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse([tente]));
    // The legit state after picking a start date (an empty start throws in
    // setEndFromSelected — ledger #34).
    container.read(startProvider.notifier).setStart('1/15/2026');

    await pumpAddEditLoan(tester, container);

    // Fresh deep link: the admin page mounts UNDERNEATH (add-edit is its
    // child) and its on-going-loan strip seeds the per-loaner item map on
    // load — so the bar arrives already populated with the real endpoint
    // data (availability is total - loaned; the caution renders raw, int
    // treated as euros — same family as the amap bug #13).
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    expect(find.textContaining('3 Available'), findsOneWidget);
    expect(find.textContaining('3000.00 €'), findsOneWidget);

    await searchItems(tester, 'Tente');

    // The search's onChanged re-seeds the map with the filtered list; the
    // card is still there.
    expect(find.textContaining('Tente 2 places'), findsOneWidget);
    expect(find.textContaining('3 Available'), findsOneWidget);
    expect(find.textContaining('3000.00 €'), findsOneWidget);

    // Plus once: quantity 1, the end date lands on start + the item's
    // suggested duration (3 days) and the caution totals 1 × 3000 €.
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
    );
    await settle(tester, frames: 6);
    expect(container.read(editSelectedListProvider), [1]);
    expect(container.read(endProvider), '1/18/2026');
    expect(container.read(cautionProvider).text, '3000.00 €');
    expect(find.textContaining('1 selected item'), findsOneWidget);

    // Minus back to zero: the empty-selection branch clears both fields.
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.minus),
    );
    await settle(tester, frames: 6);
    expect(container.read(editSelectedListProvider), [0]);
    expect(container.read(endProvider), '');
    expect(container.read(cautionProvider).text, '');
  });

  testWidgets('the plus stepper is capped at the available quantity', (
    tester,
  ) async {
    final loaner1 = loaner('loaner-1', 'Asso Matériel');
    final scarce = item('item-1', 'Perceuse', 3, 2);
    final container = scaffold.makeContainer(myLoaners: [loaner1]);
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.loansUsersMeLoanersGet(),
    ).thenAnswer((_) async => chopperListResponse([loaner1]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse([scarce]));
    container.read(startProvider.notifier).setStart('1/15/2026');

    await pumpAddEditLoan(tester, container);
    await searchItems(tester, 'Perceuse');

    final plus = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.plus,
    );
    // Available is 1 (3 total - 2 loaned): the first tap selects it, the
    // second is ignored at the cap.
    await tester.tap(plus);
    await settle(tester, frames: 6);
    expect(container.read(editSelectedListProvider), [1]);
    await tester.tap(plus);
    await settle(tester, frames: 6);
    expect(container.read(editSelectedListProvider), [1]);
    expect(container.read(endProvider), '1/18/2026');
  });

  testWidgets('a loaner without items shows the empty bar through both '
      'branches', (tester) async {
    final loaner1 = loaner('loaner-1', 'Asso Matériel');
    final emptyLoaner = loaner('loaner-2', 'Sonothèque');
    final container = scaffold.makeContainer(myLoaners: [loaner1, emptyLoaner]);
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.loansUsersMeLoanersGet(),
    ).thenAnswer((_) async => chopperListResponse([loaner1, emptyLoaner]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse([item('item-1', 'Tente 2 places', 4, 1)]),
    );
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-2',
      ),
    ).thenAnswer((_) async => chopperListResponse(<Item>[]));

    await pumpAddEditLoan(tester, container);
    // The default loaner (loaner-1) has items once searched.
    await searchItems(tester, 'Tente');
    expect(find.text('No items'), findsNothing);

    // Switch to the empty loaner: the bar map has a null entry for it —
    // the null branch of the placeholder.
    container.read(loanerIdProvider.notifier).setId('loaner-2');
    await settle(tester, frames: 10);
    expect(find.text('No items'), findsOneWidget);

    // Searching on the empty loaner sets an EMPTY data list — the isEmpty
    // branch of the placeholder.
    await searchItems(tester, 'Tente');
    expect(find.text('No items'), findsOneWidget);
    expect(find.textContaining('Tente 2 places'), findsNothing);
  });

  testWidgets('edit mode pre-selects the loaned quantities', (tester) async {
    final loaner1 = loaner('loaner-1', 'Asso Matériel');
    final tente = item('item-1', 'Tente 2 places', 4, 1);
    final container = scaffold.makeContainer(myLoaners: [loaner1]);
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.loansUsersMeLoanersGet(),
    ).thenAnswer((_) async => chopperListResponse([loaner1]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse([tente]));
    container.read(startProvider.notifier).setStart('1/15/2026');
    // The state the loan list pushes before navigating in edit mode: the
    // loan carries its itemsQty, which EditSelectedListProvider folds into
    // the initial stepper values.
    container
        .read(loanProvider.notifier)
        .setLoan(
          Loan.empty().copyWith(
            id: 'loan-1',
            borrowerId: 'user-1',
            loanerId: 'loaner-1',
            caution: '3000.00 €',
            itemsQty: [
              ItemQuantity(
                quantity: 1,
                itemSimple: ItemSimple(
                  id: 'item-1',
                  name: 'Tente 2 places',
                  loanerId: 'loaner-1',
                ),
              ),
            ],
          ),
        );

    await pumpAddEditLoan(tester, container);
    // Edit-mode header.
    expect(find.text('Edit the loan'), findsOneWidget);
    // The page re-applies the stored caution on every build.
    expect(container.read(cautionProvider).text, '3000.00 €');

    await searchItems(tester, 'Tente');

    // The stepper starts at the loaned quantity and the card is marked
    // selected (black border).
    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining('1 selected item'), findsOneWidget);
  });
}
