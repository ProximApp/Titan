import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/fund_amount_provider.dart';
import 'package:titan/mypayment/ui/pages/fund_page/confirm_button.dart';
import 'package:titan/mypayment/ui/pages/fund_page/fund_page.dart';

import '../../shared/app_scaffold.dart';

/// `FundPage` and its `ConfirmFundButton` each read TWO providers through
/// `maybeWhen(orElse: ...)`, and the two defaults are identical — zero — while
/// the arithmetic they feed is not. In `ConfirmFundButton` the cap check is
/// `amountToAdd + currentAmount <= maxBalanceAmount`, so a missing provider
/// can either CLOSE the gate (a missing cap, which is an upper bound) or OPEN
/// it (a missing balance, which is an ADDEND). Nothing in the integration file
/// can see this, because the account card refuses the tap before the sheet
/// exists whenever the TOS is unavailable — so the not-loaded branches are
/// mounted here directly, at widget level, where the card's gate does not
/// apply.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final transfers = <TransferInfo>[];

  void stubSheet({required bool walletFails, required bool tosFails}) {
    when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
      (_) async => walletFails
          ? chopper.Response(
              http.Response('{"detail": "down"}', 500),
              null,
              error: 'wallet down',
            )
          : chopper.Response(
              http.Response('body', 200),
              Wallet.empty().copyWith(id: 'wallet-1', balance: 5000),
            ),
    );
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => tosFails
          ? chopper.Response(
              http.Response('{"detail": "down"}', 500),
              null,
              error: 'tos down',
            )
          : chopper.Response(
              http.Response('body', 200),
              TOSSignatureResponse.empty().copyWith(
                acceptedTosVersion: 1,
                latestTosVersion: 1,
                maxWalletBalance: 100000,
              ),
            ),
    );
    when(
      () => scaffold.repository.mypaymentTransferInitPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      transfers.add(invocation.namedArguments[#body] as TransferInfo);
      return chopper.Response(
        http.Response('body', 200),
        PaymentUrl.empty().copyWith(url: 'https://helloasso.example/pay'),
      );
    });
    stubUrlLauncher(FakeUrlLauncher());
  }

  Future<ProviderContainer> mount(WidgetTester tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const Scaffold(body: FundPage()),
      container,
      // Deliberately wide and tall. `ConfirmFundButton`'s inner `Row` is the
      // HelloAsso logo beside "Pay with HelloAsso", and the harness font is
      // wider than the real one (convention 20) — at 420 it overflowed the row
      // by 85px. This file is about which branches the NOT-LOADED providers
      // open, not about the sheet's layout, so it takes a surface large enough
      // to keep the overflow out of the way. The phone-width layout is the
      // integration file's job.
      surface: const ui.Size(560, 1000),
    );
    await settle(tester, frames: 20);
    return container;
  }

  /// The sheet is not a route here, it is the widget under test, so the
  /// confirm button's `Navigator.pop` has nothing to pop. That is harmless —
  /// the assertions here are about whether a transfer was REQUESTED.
  Future<void> type(WidgetTester tester, String amount) async {
    for (final key in amount.split('')) {
      await tester.tap(find.text(key).last, warnIfMissed: false);
      await tester.pump();
    }
  }

  setUp(() => transfers.clear());

  testWidgets('a missing TOS zeroes the cap and refuses every amount', (
    tester,
  ) async {
    stubSheet(walletFails: false, tosFails: true);
    await mount(tester);

    // The subtitle reports the cap it will enforce, which is zero.
    expect(
      tester.widget<Text>(find.textContaining('Balance after top-up:')).data,
      contains('(max: '),
    );

    await type(tester, '1');
    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    // Fail-closed: a missing CAP is an upper bound that collapsed, so every
    // amount is refused. This is the safe direction and the reason the fix for
    // the fail-open below cannot be "never default to zero".
    expect(transfers, isEmpty);
    // The refusal raised a toast, whose 2.5s PausableTimer has to be drained
    // or the next pump fails on a pending timer (convention 21).
    await scaffold.drainToast(tester);
  });

  testWidgets('a missing wallet removes the balance from the cap check', (
    tester,
  ) async {
    // The cap is 1 000,00 and the user would hold 50,00, so the real ceiling
    // is 950,00. With the balance unavailable it reads as 0 and the ceiling
    // silently becomes the full 1 000,00.
    stubSheet(walletFails: true, tosFails: false);
    await mount(tester);

    // 500,00 would be accepted because 500 + 0 <= 1000. It should be refused,
    // because 500 + 50 would not... though 550 < 1000, so pick the amount that
    // actually separates the two: 960,00. 960 + 0 <= 1000 passes; 960 + 50 =
    // 1010 busts the cap.
    await type(tester, '960');
    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    // KNOWN BUG: the transfer is requested even though the balance that should
    // have been added to the typed amount is exactly what the check is
    // missing. The backend is the only thing left to catch this.
    expect(transfers, hasLength(1));
    expect(transfers.single.amount, 96000);
  });

  testWidgets('with both providers loaded the same amount is refused', (
    tester,
  ) async {
    // The control for the test above: identical state except the wallet
    // resolved. Without it, "the cap moved" would explain the difference.
    stubSheet(walletFails: false, tosFails: false);
    await mount(tester);

    await type(tester, '960');
    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    // 960,00 + 50,00 held = 1010,00, over the 1 000,00 cap.
    expect(transfers, isEmpty);
    await scaffold.drainToast(tester);
  });

  testWidgets('the amount is held in fundAmountProvider, not local state', (
    tester,
  ) async {
    // The sheet is stateless: every keystroke round-trips through the
    // provider, which is why the pay button's `onCloseCallback` can reset the
    // amount from OUTSIDE the sheet.
    stubSheet(walletFails: false, tosFails: false);
    final container = await mount(tester);

    await type(tester, '12,50');

    expect(container.read(fundAmountProvider), '12,50');
    container.read(fundAmountProvider.notifier).setFundAmount('');
    await tester.pump();

    expect(container.read(fundAmountProvider), isEmpty);
    expect(find.text(' ʍ'), findsNothing);
  });
}
