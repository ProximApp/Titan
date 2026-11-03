import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/fund_amount_provider.dart';
import 'package:titan/mypayment/ui/pages/fund_page/confirm_button.dart';
import 'package:titan/mypayment/ui/pages/fund_page/fund_page.dart';

import '../../shared/app_scaffold.dart';

/// The CONFIRM path of the top-up sheet, which the existing fund tests never
/// take: they all stop at a refused amount (missing TOS, missing wallet, over
/// the cap). Here the amount is valid, the transfer is created, and the
/// produced HelloAsso URL is actually launched.
///
/// What this pins is the post-success bookkeeping: the amount provider is
/// cleared (so reopening the sheet does not pre-fill a top-up that already
/// happened) and the redirect URL keeps pointing at the mypayment page so the
/// payment provider returns the user somewhere useful.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final transfers = <TransferInfo>[];

  void stubLoadedWallet() {
    when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        Wallet.empty().copyWith(id: 'wallet-1', balance: 5000),
      ),
    );
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopper.Response(
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

  setUp(() => transfers.clear());

  testWidgets('a valid amount creates the transfer, launches the URL and '
      'clears the amount', (tester) async {
    stubLoadedWallet();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const Scaffold(body: FundPage()),
      container,
      // Wide enough that the HelloAsso row does not overflow in the harness
      // font (the same surface the other fund widget test uses).
      surface: const ui.Size(560, 1000),
    );
    await settle(tester, frames: 20);

    for (final key in '10'.split('')) {
      await tester.tap(find.text(key).last, warnIfMissed: false);
      await tester.pump();
    }
    expect(container.read(fundAmountProvider), '10');

    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    // One transfer, for 10,00 € in cents, returning to the mypayment page.
    expect(transfers, hasLength(1));
    expect(transfers.single.amount, 1000);
    expect(transfers.single.redirectUrl, contains('mypayment'));
    // The sheet forgets the amount once the payment URL was launched.
    expect(container.read(fundAmountProvider), isEmpty);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused launch says so and keeps the amount for a retry', (
    tester,
  ) async {
    stubLoadedWallet();
    // No browser to hand the URL to. The button turns that into the "can't
    // open link" toast rather than a silent no-op, and must NOT clear the
    // amount: nothing was paid, so the user has to be able to try again.
    stubUrlLauncher(FakeUrlLauncher(launchSucceeds: false));
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const Scaffold(body: FundPage()),
      container,
      surface: const ui.Size(560, 1000),
    );
    await settle(tester, frames: 20);

    for (final key in '10'.split('')) {
      await tester.tap(find.text(key).last, warnIfMissed: false);
      await tester.pump();
    }
    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    // The transfer was still created server-side; only the launch failed.
    expect(transfers, hasLength(1));
    expect(find.text("Can't open link"), findsOneWidget);
    expect(container.read(fundAmountProvider), '10');
    await scaffold.drainToast(tester);
  });
}
