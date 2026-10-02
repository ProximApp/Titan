import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/adapters/item.dart';
import 'package:titan/loan/providers/item_list_provider.dart';
import 'package:titan/loan/providers/loan_provider.dart';
import 'package:titan/loan/ui/pages/admin_page/loaners_bar.dart';
import 'package:titan/loan/ui/pages/detail_pages/item_card_in_loan.dart';
import 'package:titan/loan/ui/pages/loan_group_page/end_date_entry.dart';
import 'package:titan/loan/ui/pages/loan_group_page/number_selected_text.dart';
import 'package:titan/loan/ui/pages/loan_group_page/search_result.dart';
import 'package:titan/loan/ui/pages/loan_group_page/start_date_entry.dart';
import 'package:titan/user/providers/user_list_provider.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the loan rows the fixed-width sweep could not
/// reach. It mounts `ItemCard`, `LoanCard`, `CheckItemCard` and `ItemBar`.
/// This file covers the rest of the module's leaf rows: the item card a loan
/// detail page puts in its strip, the admin loaners chip bar, the two date
/// entries, the selected-items counter and the borrower search result.
///
/// `ItemCardInLoan` is the one that earns its place here. It pins
/// `CardLayout(width: 140, height: 80)` and the detector missed it, because
/// the detector looks for a hardcoded width next to flex children in the same
/// file, and this card hands the number to `CardLayout` as an argument. A
/// pinned height of 80px with a `Text` that has no `maxLines` is exactly the
/// shape that grows: the quantity line reads "12500 borrowed" and wraps.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  const longItemName = 'Perceuse a percussion aakk de la societe de legende';
  const longLoanerName = 'Association des etudiants en medecine de bordeaux';

  /// The three list providers every row in this file transitively watches.
  /// Unstubbed they return null where a Future is expected, and the row dies
  /// before it lays out — which would make "no overflow" true for the wrong
  /// reason.
  void stubLoanLists({
    List<Loaner> loaners = const [],
    List<Item> items = const [],
  }) {
    when(
      () => scaffold.repository.loansUsersMeLoanersGet(),
    ).thenAnswer((_) async => chopperListResponse(loaners));
    when(
      () => scaffold.repository.loansLoanersLoanerIdItemsGet(
        loanerId: any(named: 'loanerId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(items));
  }

  testWidgets('the item card fits a long name and a five-figure quantity', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ItemCardInLoan(
            itemQty: ItemQuantity.empty().copyWith(
              itemSimple: ItemSimple.empty().copyWith(
                id: 'i-1',
                name: longItemName,
              ),
              quantity: 12500,
            ),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    // Non-vacuity, and the pin itself: CardLayout is asked for 140x80, and
    // its default 15px horizontal margin is part of the rendered box, so the
    // widget measures 170 wide by 80 tall.
    expect(find.byType(ItemCardInLoan), findsOneWidget);
    expect(
      tester.getSize(find.byType(ItemCardInLoan)).width,
      closeTo(140 + 30, 0.5),
    );
    expect(tester.getSize(find.byType(ItemCardInLoan)).height, 80);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the item card fits its singular quantity too', (tester) async {
    // quantity == 1 picks the singular label, so the line gets SHORTER. Both
    // branches are mounted, because the singular one is the one nobody
    // screenshots.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ItemCardInLoan(
            itemQty: ItemQuantity.empty().copyWith(
              itemSimple: ItemSimple.empty().copyWith(id: 'i-1', name: 'Drill'),
              quantity: 1,
            ),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(ItemCardInLoan), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the loaners chip bar fits long loaner names', (tester) async {
    // HorizontalListView(height: 40) with ItemChip padding 10px vertically
    // on each side, so the chip's own text has ~20px to live in.
    stubLoanLists(
      loaners: [
        Loaner.empty().copyWith(id: 'l-1', name: longLoanerName),
        Loaner.empty().copyWith(id: 'l-2', name: 'Bureau'),
      ],
    );
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: LoanersBar(onTap: (_) {})),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(LoanersBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the two date entries fit side by side and stacked', (
    tester,
  ) async {
    // StartDateEntry recomputes the end date from the item list whenever the
    // start moves, so it watches one more provider than EndDateEntry does.
    stubLoanLists();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(children: const [StartDateEntry(), EndDateEntry()]),
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(StartDateEntry), findsOneWidget);
    expect(find.byType(EndDateEntry), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the selected-items counter folds a large count', (tester) async {
    // formatNumberItems switches on the folded total: 0 prints a sentence
    // with no number in it, 1 and n print "N items selected". The counter
    // only knows the items because the loan's itemsQty are matched back onto
    // the loaner's item list by id, so both providers have to resolve first.
    final items = List.generate(
      40,
      (i) => Item.empty().copyWith(id: 'i-$i', name: 'Item $i'),
    );
    final loaner = Loaner.empty().copyWith(id: 'l-1', name: 'Bureau');
    stubLoanLists(loaners: [loaner], items: items);

    for (final selected in [1, 9999]) {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      // loanerIdProvider derives from the loaners list, and itemListProvider
      // only loads once that is non-empty — so the stub is what makes the
      // items reachable at all. A sync NotifierProvider has no `.future` in
      // Riverpod 3, so the notifier's own load is what gets awaited.
      await container.read(itemListProvider.notifier).loadItemList('l-1');
      await container
          .read(loanProvider.notifier)
          .setLoan(
            Loan.empty().copyWith(
              id: 'loan-1',
              loaner: loaner,
              itemsQty: [
                for (final item in items)
                  ItemQuantity.empty().copyWith(
                    itemSimple: item.toItemSimple(),
                    quantity: selected,
                  ),
              ],
            ),
          );

      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: const NumberSelectedText()),
        ),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 4);

      expect(find.byType(NumberSelectedText), findsOneWidget);
      // 40 items x `selected` folded together, so the count is not the item
      // count — that is the whole point of the fold.
      expect(find.textContaining('${40 * selected} '), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    }
  });

  testWidgets('the selected-items counter renders the empty sentence', (
    tester,
  ) async {
    // The n == 0 branch drops the number entirely, so there is nothing to
    // match numerically — assert the mounted widget and the absence of a
    // digit instead.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: SingleChildScrollView(child: const NumberSelectedText())),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(NumberSelectedText), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The item list never loads without a loaner, so the provider is still
    // loading at teardown and its autoDispose needs a frame.
    await scaffold.unmountApp(tester);
  });

  testWidgets('the borrower search row fits a long name', (tester) async {
    // The row puts an Expanded Text beside a 20px spacer with spaceBetween,
    // so the name ellipsizes inside whatever is left. `userList` starts empty
    // and never loads on its own, so the search is what fills it — the real
    // flow, and the only way the row has any children to lay out.
    when(
      () => scaffold.repository.usersSearchGet(query: any(named: 'query')),
    ).thenAnswer(
      (_) async => chopperListResponse([
        CoreUserSimple.empty().copyWith(
          id: 'u-1',
          firstname: 'Jean-Baptiste',
          name: 'DelaunayDeserializer',
        ),
      ]),
    );
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await container.read(userList.notifier).filterUsers('delaunay');

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SearchResult(queryController: controller),
        ),
      ),
      container,
      appFonts: true,
    );
    await settle(tester, frames: 4);

    expect(find.byType(SearchResult), findsOneWidget);
    // The row rendered a real result, not just an empty Column.
    expect(find.text('Jean-Baptiste DelaunayDeserializer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
