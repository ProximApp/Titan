import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/ui/components/digit_fade_in_animation.dart';
import 'package:titan/mypayment/ui/components/transaction_card.dart';
import 'package:titan/mypayment/ui/pages/store_stats_page/refund_page.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The store-stats refund sheet — `refund_page.dart` was 76 lines with ZERO
/// coverage.
///
/// It is a `showModalBottomSheet` hanging off ONE tap in
/// `StoreTransactionsDetail`: a transaction card whose status is confirmed,
/// whose type is `requestTransaction`, and whose store's seller record has
/// `canCancel`. Nothing in the suite built a seller with the cancel right, so
/// every transaction silently failed the gate and the sheet never opened.
///
/// The sheet itself is a numeric keypad over a `refundAmountProvider` string,
/// and its confirm button POSTs `mypaymentTransactionsTransactionIdRefundPost`
/// with the amount in cents.
void stubRefund(
  IntegrationScaffold scaffold, {
  required List<History> storeHistory,
  bool sellerCanCancel = true,
  bool refundSucceeds = true,
}) {
  // `canCancel` is a field of the STORE record the stores endpoint returns
  // (selectedStoreProvider hands it straight to the sheet's gate), not of the
  // seller list — the shared `myPaymentStore` fixture has it false, which is
  // why no test had ever reached the refund sheet.
  when(() => scaffold.repository.mypaymentUsersMeStoresGet()).thenAnswer(
    (_) async => chopperListResponse([
      myPaymentStore.copyWith(canCancel: sellerCanCancel),
    ]),
  );
  when(
    () => scaffold.repository.mypaymentStoresStoreIdHistoryGet(
      storeId: 'store-1',
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => chopperListResponse(storeHistory));
  // `selectedStore.canCancel` is the SIGNED-IN seller's right, not the
  // store's: StoreTransactionsDetail reads it off selectedStoreProvider.
  when(
    () => scaffold.repository.mypaymentStoresStoreIdSellersGet(
      storeId: 'store-1',
    ),
  ).thenAnswer(
    (_) async => chopperListResponse([
      Seller(
        userId: 'user-1',
        storeId: 'store-1',
        canBank: true,
        canSeeHistory: true,
        canCancel: sellerCanCancel,
        canManageSellers: false,
        canManageEvents: false,
        user: CoreUserSimple.empty().copyWith(id: 'user-1'),
      ),
    ]),
  );
  when(
    () => scaffold.repository.mypaymentTransactionsTransactionIdRefundPost(
      transactionId: any(named: 'transactionId'),
      body: any(named: 'body'),
    ),
  ).thenAnswer(
    (_) async => refundSucceeds
        ? chopperResponse(History.empty())
        : chopper.Response(http.Response('{"detail": "refused"}', 400), null),
  );
}

/// A transaction the refund sheet is allowed to open for: confirmed and a
/// `requestTransaction` (a direct store transaction is never refundable).
History refundableTransaction({
  String id = 'h-1',
  int total = 5000,
  HistoryType type = HistoryType.requestTransaction,
  TransactionStatus status = TransactionStatus.confirmed,
}) => History.empty().copyWith(
  id: id,
  type: type,
  direction: HistoryDirection.credited,
  otherWalletName: 'BDE',
  total: total,
  creation: DateTime(2026, 1, 5, 12, 30),
  status: status,
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> openStoreStats(WidgetTester tester) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/storeStats',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
  }

  /// displayToast arms a 2.5s PausableTimer; a test that ends while it is
  /// pending fails with "A Timer is still pending" and then poisons the next
  /// test in the isolate. Step through frames to drain it.
  Future<void> drainToast(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('a confirmed request transaction opens the refund sheet', (
    tester,
  ) async {
    stubRefund(scaffold, storeHistory: [refundableTransaction(total: 5000)]);
    await openStoreStats(tester);

    // The transaction card is on screen (it renders `transactionName`, not
    // the wallet name, so target the widget itself).
    expect(find.byType(TransactionCard), findsWidgets);

    // ... and tapping it opens the refund sheet.
    await tester.tap(find.byType(TransactionCard).first);
    await settle(tester, frames: 30);

    expect(find.byType(ReFundPage), findsOneWidget);
    expect(
      find.text('Refund'),
      findsNWidgets(2),
      reason: 'sheet title + action',
    );
    // The sheet names the other wallet and the refundable maximum (5000 cents
    // -> 50.00, in the ʍ currency).
    expect(find.textContaining('BDE (max:'), findsOneWidget);
    expect(find.textContaining('50'), findsWidgets);
    // No amount entered yet, so no digits and no currency marker.
    expect(find.text(' ʍ'), findsNothing);
  });

  testWidgets('the keypad fills the amount and the refund POSTs cents', (
    tester,
  ) async {
    stubRefund(scaffold, storeHistory: [refundableTransaction(total: 5000)]);
    await openStoreStats(tester);
    await tester.tap(find.byType(TransactionCard).first);
    await settle(tester, frames: 30);

    // The confirm button only anchors to the bottom of the sheet, which
    // NavigationTemplate paints UNDER the floating navbar: without the sheet
    // hiding it, this tap lands on the navbar and nothing happens.
    expect(
      find.widgetWithText(WaitingButton, 'Refund').hitTestable(),
      findsOneWidget,
    );

    // Type 12,5 on the shared NumericKeyboard (the sheet's max is 50,00).
    for (final key in ['1', '2', ',', '5']) {
      await tester.tap(find.widgetWithText(InkWell, key).first);
      await settle(tester, frames: 4);
    }
    expect(find.text(' ʍ'), findsOneWidget);
    // Each digit appears twice: on its key, and in the amount display.
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('5'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(WaitingButton, 'Refund'));
    await settle(tester, frames: 40);

    final captured =
        verify(
              () => scaffold.repository
                  .mypaymentTransactionsTransactionIdRefundPost(
                    transactionId: 'h-1',
                    body: captureAny(named: 'body'),
                  ),
            ).captured.single
            as RefundInfo;
    expect(captured.amount, 1250, reason: '12.50 euros in cents');
    expect(captured.completeRefund, isFalse);

    // The sheet closes and reports success.
    expect(find.byType(ReFundPage), findsNothing);
    expect(find.text('Transaction completed'), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets('an amount above the maximum is refused', (tester) async {
    stubRefund(scaffold, storeHistory: [refundableTransaction(total: 5000)]);
    await openStoreStats(tester);
    await tester.tap(find.byType(TransactionCard).first);
    await settle(tester, frames: 30);

    // 9,9 is 99.00 on a 50,00 refundable transaction. The sheet paints the
    // amount red while it is invalid, and the confirm button used to POST it
    // anyway: the backend was asked to refund twice what is refundable.
    for (final digit in ['9', '9']) {
      await tester.tap(find.widgetWithText(InkWell, digit).first);
      await settle(tester, frames: 4);
    }
    // The display digits are the ones wrapped in DigitFadeInAnimation (the
    // keypad keys are bare Text).
    final display = find.descendant(
      of: find.byType(DigitFadeInAnimation),
      matching: find.text('9'),
    );
    expect(display, findsNWidgets(2), reason: 'the amount 99 is two digits');
    expect(
      tester.widget<Text>(display.first).style?.color,
      const Color.fromARGB(255, 91, 6, 0),
      reason: 'invalid amount is shown in red',
    );

    await tester.tap(find.widgetWithText(WaitingButton, 'Refund'));
    await settle(tester, frames: 20);

    expect(find.text('Please enter a valid amount'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.mypaymentTransactionsTransactionIdRefundPost(
        transactionId: any(named: 'transactionId'),
        body: any(named: 'body'),
      ),
    );
    expect(find.byType(ReFundPage), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets('the backspace key erases the last digit', (tester) async {
    stubRefund(scaffold, storeHistory: [refundableTransaction()]);
    await openStoreStats(tester);
    await tester.tap(find.byType(TransactionCard).first);
    await settle(tester, frames: 30);

    for (final digit in ['4', '2']) {
      await tester.tap(find.widgetWithText(InkWell, digit).first);
      await settle(tester, frames: 4);
    }
    expect(find.text('2'), findsNWidgets(2), reason: 'key + display');

    // The erase key is the keypad's backspace icon (the digits are InkWells).
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.backspace,
      ),
    );
    await settle(tester, frames: 6);

    // Only the key is left for 2; the display lost its last digit.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsNWidgets(2));
  });

  testWidgets('an empty amount is refused instead of crashing', (tester) async {
    stubRefund(scaffold, storeHistory: [refundableTransaction()]);
    await openStoreStats(tester);
    await tester.tap(find.byType(TransactionCard).first);
    await settle(tester, frames: 30);

    // The confirm button had no validity gate: with nothing typed it used to
    // reach `double.parse('')`, which throws FormatException out of the sheet.
    await tester.tap(find.widgetWithText(WaitingButton, 'Refund'));
    await settle(tester, frames: 20);

    expect(tester.takeException(), isNull);
    expect(find.text('Please enter a valid amount'), findsOneWidget);
    // And nothing was posted.
    verifyNever(
      () => scaffold.repository.mypaymentTransactionsTransactionIdRefundPost(
        transactionId: any(named: 'transactionId'),
        body: any(named: 'body'),
      ),
    );
    expect(find.byType(ReFundPage), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets('a refused refund shows an error and keeps the sheet open', (
    tester,
  ) async {
    stubRefund(
      scaffold,
      storeHistory: [refundableTransaction()],
      refundSucceeds: false,
    );
    await openStoreStats(tester);
    await tester.tap(find.byType(TransactionCard).first);
    await settle(tester, frames: 30);
    await tester.tap(find.widgetWithText(InkWell, '3').first);
    await settle(tester, frames: 4);

    await tester.tap(find.widgetWithText(WaitingButton, 'Refund'));
    await settle(tester, frames: 30);

    // The POST happened but failed: the sheet must not close, and the toast
    // must not claim the transaction completed. `refundTransaction` answers
    // data(false) on a refused response, so the old `data:`-blind branch
    // toasted success and popped.
    verify(
      () => scaffold.repository.mypaymentTransactionsTransactionIdRefundPost(
        transactionId: 'h-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    expect(find.byType(ReFundPage), findsOneWidget);
    expect(find.text('Transaction completed'), findsNothing);
    expect(find.text('Error while deleting'), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets('a seller without the cancel right cannot open the sheet', (
    tester,
  ) async {
    stubRefund(
      scaffold,
      storeHistory: [refundableTransaction()],
      sellerCanCancel: false,
    );
    await openStoreStats(tester);

    await tester.tap(find.byType(TransactionCard).first);
    await settle(tester, frames: 30);

    expect(find.byType(ReFundPage), findsNothing);
  });

  testWidgets('a pending or direct transaction cannot be refunded', (
    tester,
  ) async {
    stubRefund(
      scaffold,
      storeHistory: [
        refundableTransaction(id: 'h-1', status: TransactionStatus.pending),
        refundableTransaction(id: 'h-2', type: HistoryType.directTransaction),
      ],
    );
    await openStoreStats(tester);

    for (final card in find.byType(TransactionCard).evaluate().toList()) {
      await tester.tap(find.byElementPredicate((e) => e == card));
      await settle(tester, frames: 20);
    }

    expect(find.byType(ReFundPage), findsNothing);
  });
}
