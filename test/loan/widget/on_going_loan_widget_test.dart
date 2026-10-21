import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/admin_loan_list_provider.dart';
import 'package:titan/loan/providers/item_list_provider.dart';
import 'package:titan/loan/providers/loaner_loan_list_provider.dart';
import 'package:titan/loan/providers/loaners_items_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/loan/ui/pages/admin_page/loan_card.dart';
import 'package:titan/loan/ui/pages/admin_page/on_going_loan.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// Widget-level coverage for `OnGoingLoan`: the sorted list, the live
/// search, the delay dialog's extend path and the return confirmation's
/// failure path. The QR-routing branches belong to the integration level.
class _LoanListNotifier extends LoanerLoanListNotifier {
  _LoanListNotifier(this.loans);

  final List<Loan> loans;

  @override
  AsyncValue<List<Loan>> build() => AsyncValue.data(loans);
}

class _ItemsNotifier extends ItemListNotifier {
  @override
  AsyncValue<List<Item>> build() => const AsyncValue.loading();
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Pumps fixed frames plus a long jump: the actions answer with toasts
  /// whose auto-close timer must not outlive the test.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  Loan loanFixture({required String id, required DateTime end}) =>
      Loan.empty().copyWith(
        id: id,
        start: DateTime(2026, 10, 1),
        end: end,
        borrower: CoreUserSimple.empty().copyWith(
          id: 'b-1',
          name: 'Dupont',
          firstname: 'Alice',
        ),
      );

  ProviderContainer containerWith(List<Loan> loans) {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        itemListProvider.overrideWith(_ItemsNotifier.new),
        loanerLoanListProvider.overrideWith(() => _LoanListNotifier(loans)),
        // The loaner key the section reads by derives from this list; the
        // repository-backed notifier flips loading → error asynchronously
        // and rebuilds `AdminLoanListNotifier`, wiping a map seeded before
        // the pump. The fake holds one stable entry instead.
        notifierBuildOverride(
          userLoanerListProvider,
          AsyncValue.data([Loaner.empty()]),
        ),
      ],
    );
    addTearDown(container.dispose);
    // The section reads the per-loaner map; the loaner key defaults to empty.
    container
        .read(adminLoanListProvider.notifier)
        .setTData(Loaner.empty(), AsyncValue.data(loans));
    container
        .read(loanersItemsProvider.notifier)
        .setTData(Loaner.empty(), const AsyncValue.data([]));
    return container;
  }

  Future<void> mount(
    WidgetTester tester,
    ProviderContainer container, {
    ui.Size? surface,
  }) async {
    if (surface == null) {
      await scaffold.pumpWidgetApp(tester, const OnGoingLoan(), container);
      return;
    }
    await scaffold.pumpWidgetApp(
      tester,
      const OnGoingLoan(),
      container,
      surface: surface,
    );
  }

  testWidgets('lists the loans sorted by end date', (tester) async {
    final container = containerWith([
      loanFixture(id: 'l-late', end: DateTime(2026, 12, 1)),
      loanFixture(id: 'l-early', end: DateTime(2026, 10, 20)),
    ]);
    await mount(tester, container);

    // The horizontal list builds lazily, so only the first card is up at
    // once — and it is the early loan even though the input starts with the
    // late one, which is what proves the end-date sort.
    expect(find.byType(LoanCard), findsOneWidget);
    expect(tester.widget<LoanCard>(find.byType(LoanCard)).loan.id, 'l-early');

    await tester.drag(find.byType(LoanCard), const Offset(-500, 0));
    await pumpFrames(tester);
    final visible = tester
        .widgetList<LoanCard>(find.byType(LoanCard))
        .map((c) => c.loan.id)
        .toList();
    expect(visible, contains('l-late'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search bar filters the section list', (tester) async {
    final container = containerWith([
      loanFixture(id: 'l-1', end: DateTime(2026, 10, 20)),
    ]);
    await mount(tester, container);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await pumpFrames(tester);
    expect(find.byType(LoanCard), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Dupont');
    await pumpFrames(tester);
    expect(find.byType(LoanCard), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '');
    await pumpFrames(tester);
    expect(find.byType(LoanCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the delay dialog extends the loan through the API', (
    tester,
  ) async {
    final repo = scaffold.repository;
    when(
      () => repo.loansLoanIdExtendPost(
        loanId: 'l-1',
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => repo.okVoid());

    final container = containerWith([
      loanFixture(id: 'l-1', end: DateTime(2026, 10, 20)),
    ]);
    await mount(tester, container, surface: const ui.Size(700, 1000));

    // LoanCard exposes calendar first, then return.
    final cardButtons = find.descendant(
      of: find.byType(LoanCard),
      matching: find.byType(WaitingButton),
    );
    await tester.tap(cardButtons.first);
    // Bounded pumps: the WaitingButton swaps in a spinning Loader while the
    // action runs, which pumpAndSettle would wait on forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Extension delay'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester);

    verify(
      () => repo.loansLoanIdExtendPost(
        loanId: 'l-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refused return toasts and keeps the section alive', (
    tester,
  ) async {
    final repo = scaffold.repository;
    when(() => repo.loansLoanIdReturnPost(loanId: 'l-1'))
        .thenAnswer((_) async => repo.fail<void>(400));

    final container = containerWith([
      loanFixture(id: 'l-1', end: DateTime(2026, 10, 20)),
    ]);
    // Wide surface: at 360 the card's right-hand buttons sit past the
    // viewport edge and tap() misses them.
    await mount(tester, container, surface: const ui.Size(700, 1000));

    final cardButtons = find.descendant(
      of: find.byType(LoanCard),
      matching: find.byType(WaitingButton),
    );
    await tester.tap(cardButtons.last);
    // Bounded pumps (the WaitingButton Loader spins forever).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(CustomDialogBox), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester);

    verify(() => repo.loansLoanIdReturnPost(loanId: 'l-1')).called(1);
    expect(find.byType(CustomDialogBox), findsNothing);
    expect(find.byType(LoanCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
