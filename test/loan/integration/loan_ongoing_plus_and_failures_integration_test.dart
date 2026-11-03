import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart' show TextButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/adapters/item.dart';
import 'package:titan/loan/providers/loaners_items_provider.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/loan/ui/pages/admin_page/delay_dialog.dart';
import 'package:titan/loan/ui/pages/admin_page/loan_card.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/horizontal_list_view.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';
import '../loan_fixtures.dart';

/// Three ongoing-loan paths the flows file leaves out.
///
///  * The strip's FIRST card is the create shortcut — a plus card whose
///    handler seeds an empty loan, today's start date, no end date and the
///    item list, then routes to the form. No existing test pressed it (the
///    other file starts from a seeded loan and only touches the real card).
///  * A REFUSED extension: the flows file extends successfully, so the
///    error toast was never shown.
///  * A return while the loaner's ITEMS are still loading: the handler reads
///    them to keep item quantities in sync and has an `orElse` for exactly
///    that state, which only happens when the strip is used before the item
///    list arrives.
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

  Future<void> pumpAdmin(WidgetTester tester) async {
    // Convention 20: the harness font draws every glyph as a square, so the
    // card's pinned 250x170 box overflows where real Roboto would not.
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
  }

  testWidgets('the strip\'s plus card starts a new loan on today\'s date', (
    tester,
  ) async {
    await pumpAdmin(tester);

    // The plus is the strip's first child, outside any LoanCard. The shell
    // draws an add icon of its own, so scope the tap to the strip.
    expect(find.byType(LoanCard), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(HorizontalListView<Loan>),
        matching: heroIcon(HeroIcons.plus),
      ),
    );
    await settle(tester, frames: 40);

    // The handler seeded the empty loan and routed to the create form.
    expect(
      QR.currentPath,
      '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.addEditLoan}',
    );
    expect(find.text('Add a loan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refused extension reports the extending error', (
    tester,
  ) async {
    await pumpAdmin(tester);
    when(
      () => scaffold.repository.loansLoanIdExtendPost(
        loanId: any(named: 'loanId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 500),
        null,
      ),
    );

    final card = find.byType(LoanCard);
    await tester.tap(
      find.descendant(of: card, matching: heroIcon(HeroIcons.calendarDays)),
    );
    await settle(tester, frames: 4);
    expect(find.byType(DelayDialog), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    // The refusal does not pretend the loan moved: error toast, card intact.
    expect(find.text('Error while extending'), findsOneWidget);
    expect(find.text('Extended loan'), findsNothing);
    expect(find.byType(LoanCard), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a return with the item list still loading still completes', (
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
    ).thenAnswer((_) async => chopperListResponse([loan]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
        returned: true,
      ),
    ).thenAnswer((_) async => chopperListResponse(<Loan>[]));
    when(
      () => scaffold.repository.loansLoanIdReturnPost(
        loanId: any(named: 'loanId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${LoanRouter.root}${LoanRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    // The strip reads the loaner's items to keep quantities in sync; put that
    // entry back into loading, the state a slow item fetch leaves behind.
    container
        .read(loanersItemsProvider.notifier)
        .setTData(loaner, const AsyncValue.loading());
    await settle(tester, frames: 4);

    final card = find.byType(LoanCard);
    await tester.tap(
      find.descendant(of: card, matching: heroIcon(HeroIcons.check)),
    );
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(CustomDialogBox),
        matching: find.text('Confirm'),
      ),
    );
    await settle(tester, frames: 20);

    // No items to merge is not a failure: the loan is returned and the card
    // leaves the strip.
    expect(tester.takeException(), isNull);
    expect(find.text('Returned loan'), findsOneWidget);
    expect(find.byType(LoanCard), findsNothing);
    await scaffold.drainToast(tester);
  });

  testWidgets('a history card carries its loan to the admin detail', (
    tester,
  ) async {
    await loadAppFonts();
    final historical = loanFixture(
      id: 'h-1',
      borrower: coreUserSimpleFixture(
        id: 'u-2',
        firstname: 'Marc',
        name: 'Rue',
      ),
      loaner: loaner,
      returned: true,
      returnedDate: DateTime(2026, 1, 3),
    );
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
    ).thenAnswer((_) async => chopperListResponse([loan]));
    when(
      () => scaffold.repository.loansLoanersLoanerIdLoansGet(
        loanerId: 'loaner-1',
        returned: true,
      ),
    ).thenAnswer((_) async => chopperListResponse([historical]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${LoanRouter.root}${LoanRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    // The history strip renders the same card with the history flag set; its
    // only affordance is the info button, which seeds the loan detail route.
    final historyCard = find.byWidgetPredicate(
      (w) => w is LoanCard && w.isHistory,
      description: 'history LoanCard',
    );
    expect(historyCard, findsOneWidget);
    await tester.tap(historyCard);
    await settle(tester, frames: 40);

    expect(
      QR.currentPath,
      '${LoanRouter.root}${LoanRouter.admin}${LoanRouter.detail}',
    );
    expect(find.textContaining('Marc Rue'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the create form refuses an empty borrower', (tester) async {
    await pumpAdmin(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(HorizontalListView<Loan>),
        matching: heroIcon(HeroIcons.plus),
      ),
    );
    await settle(tester, frames: 40);
    expect(find.text('Add a loan'), findsOneWidget);

    // Submitting an untouched create form trips the validator, which the form
    // reports with its own toast instead of sending anything.
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 10);

    expect(find.text('Some fields are missing or incorrect'), findsOneWidget);
    expect(find.text('Add a loan'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('cancelling the extension dialog sends nothing', (tester) async {
    await pumpAdmin(tester);
    var extensions = 0;
    when(
      () => scaffold.repository.loansLoanIdExtendPost(
        loanId: any(named: 'loanId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {
      extensions++;
      return chopperResponseVoid();
    });

    await tester.tap(
      find.descendant(
        of: find.byType(LoanCard),
        matching: heroIcon(HeroIcons.calendarDays),
      ),
    );
    await settle(tester, frames: 4);
    expect(find.byType(DelayDialog), findsOneWidget);

    // Cancel is the dialog's first action: it pops without calling onYes.
    await tester.tap(
      find
          .descendant(
            of: find.byType(DelayDialog),
            matching: find.byType(TextButton),
          )
          .first,
    );
    await settle(tester, frames: 6);

    expect(find.byType(DelayDialog), findsNothing);
    expect(extensions, 0);
    expect(find.byType(LoanCard), findsOneWidget);
  });

  testWidgets('the picker changes the requested delay', (tester) async {
    await pumpAdmin(tester);
    int? asked;
    when(
      () => scaffold.repository.loansLoanIdExtendPost(
        loanId: any(named: 'loanId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      asked = (inv.namedArguments[#body] as LoanExtend).duration;
      return chopperResponseVoid();
    });

    await tester.tap(
      find.descendant(
        of: find.byType(LoanCard),
        matching: heroIcon(HeroIcons.calendarDays),
      ),
    );
    await settle(tester, frames: 4);

    // The picker starts at 5 days; a wheel drag must reach the request.
    await tester.fling(find.byType(NumberPicker), const Offset(0, -60), 1200);
    await settle(tester, frames: 12);
    await tester.tap(
      find.descendant(
        of: find.byType(DelayDialog),
        matching: find.text('Confirm'),
      ),
    );
    await settle(tester, frames: 12);

    expect(asked, isNotNull);
    expect(asked, isNot(5));
    await scaffold.drainToast(tester);
  });

  testWidgets('a returned loan without a date says so', (tester) async {
    await loadAppFonts();
    final dateless = loanFixture(
      id: 'h-2',
      borrower: coreUserSimpleFixture(id: 'u-3', firstname: 'Sacha', name: 'L'),
      loaner: loaner,
      returned: true,
      returnedDate: null,
    );
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
    ).thenAnswer((_) async => chopperListResponse([dateless]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${LoanRouter.root}${LoanRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    // The card falls back to the localised placeholder rather than
    // formatting null into a date.
    expect(find.text('No return date'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
