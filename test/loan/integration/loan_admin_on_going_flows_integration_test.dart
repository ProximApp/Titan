import 'package:flutter/material.dart' show IconButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/adapters/item.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/admin_page/delay_dialog.dart';
import 'package:titan/loan/ui/pages/admin_page/loan_card.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// The four card handlers of the admin's ongoing-loan strip, in one journey:
/// the extension dialog (DelayDialog's confirm feeds `extendLoan`), the
/// pencil round trip into the edit form and back through the TopBar chevron,
/// the card's own tap (admin mode routes the WHOLE card to the admin detail)
/// and the return confirmation that ends it. The return runs last because it
/// removes the loan from the strip.
void main() {
  late IntegrationScaffold scaffold;

  final loaner = loanerFixture(
    id: 'loaner-1',
    name: 'Asso Matériel',
    groupManagerId: 'grp-1',
  );
  final tent = itemFixture(
    id: 'item-1',
    name: 'Tente 2 places',
    loanerId: 'loaner-1',
    totalQuantity: 4,
  );
  final loan = loanFixture(
    id: 'l-1',
    borrower: coreUserSimpleFixture(id: 'u-1', firstname: 'Jane', name: 'Doe'),
    loaner: loaner,
    itemsQty: [ItemQuantity(itemSimple: tent.toItemSimple(), quantity: 1)],
  );

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Finder heroIcon(HeroIcons icon) => find.byWidgetPredicate(
    (w) => w is HeroIcon && w.icon == icon,
    description: 'HeroIcon($icon)',
  );

  void expectNoOverflow(WidgetTester t, String phase) {
    expect(
      t.takeException(),
      isNull,
      reason: 'no layout exception after $phase',
    );
  }

  testWidgets('the ongoing-loan card extends, edits, opens and returns', (
    tester,
  ) async {
    // Convention 20: the harness font draws every glyph as a square of the
    // font size, so "1 Tente 2 places" wraps to two lines inside the card's
    // pinned 250x170 box and reports a RenderFlex overflow that real Roboto
    // does not produce. Load the bundled faces before judging layout.
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
    // The ongoing strip asks WITHOUT the `returned` flag, the history panel
    // WITH `returned: true` — two stubs, two argument sets.
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
      ),
    ).thenAnswer((_) async => chopperListResponse([loan]));
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

    final card = find.byType(LoanCard);
    expect(card, findsOneWidget);

    // 1 — Extension: calendar icon → DelayDialog → confirm (default 5 days).
    var extensions = 0;
    LoanExtend? extension;
    when(
      () => scaffold.repository.loansLoanIdExtendPost(
        loanId: any(named: 'loanId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      extensions++;
      expect(inv.namedArguments[#loanId], 'l-1');
      extension = inv.namedArguments[#body] as LoanExtend;
      return chopperResponseVoid();
    });

    await tester.tap(
      find.descendant(of: card, matching: heroIcon(HeroIcons.calendarDays)),
    );
    await settle(tester, frames: 4);
    expect(find.byType(DelayDialog), findsOneWidget);
    expect(find.text('Extension delay'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 10);
    expect(extensions, 1);
    expect(extension!.duration, 5);
    // Still on the admin page: the card survives an extension.
    expect(find.byType(LoanCard), findsOneWidget);
    expectNoOverflow(tester, 'after extend');

    // 2 — Edit: pencil → the edit form → TopBar chevron back.
    await tester.tap(
      find.descendant(of: card, matching: heroIcon(HeroIcons.pencil)),
    );
    await settle(tester, frames: 40);
    expect(find.text('Edit the loan'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await settle(tester, frames: 40);
    expect(find.text('Edit the loan'), findsNothing);
    expect(find.byType(LoanCard), findsOneWidget);
    expectNoOverflow(tester, 'after edit round trip');

    // 3 — Info: in admin mode the card's own tap routes to the admin detail.
    await tester.tap(find.byType(LoanCard));
    await settle(tester, frames: 40);
    expect(find.textContaining('Jane Doe'), findsWidgets);

    await tester.tap(find.byType(IconButton));
    await settle(tester, frames: 40);
    expect(find.byType(LoanCard), findsOneWidget);
    expectNoOverflow(tester, 'after info round trip');

    // 4 — Return: check → confirmation → DELETE-shaped round trip → gone.
    var returns = 0;
    when(
      () => scaffold.repository.loansLoanIdReturnPost(
        loanId: any(named: 'loanId'),
      ),
    ).thenAnswer((inv) async {
      returns++;
      expect(inv.namedArguments[#loanId], 'l-1');
      return chopperResponseVoid();
    });

    await tester.tap(
      find.descendant(of: card, matching: heroIcon(HeroIcons.check)),
    );
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    expect(find.text('Return the loan?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(CustomDialogBox),
        matching: find.text('Confirm'),
      ),
    );
    await settle(tester, frames: 20);
    expect(returns, 1);
    expect(find.byType(LoanCard), findsNothing);
    await scaffold.drainToast(tester);
  });
}
