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
import 'package:titan/tools/functions.dart';

import '../../shared/app_scaffold.dart';

/// A popup the button ASKED to open, kept instead of opened.
///
/// Off the browser the real shim resolves to `else.dart`, whose only statement
/// is a throw, so every web path in this button — the site redirect URL, the
/// popup call itself, the success and cancelled callbacks, the blocked-popup
/// error — was unreachable from the VM run. The `isWeb` / `openWindow` seams
/// exist for exactly this file; production still passes `kIsWeb` and the real
/// shim.
class _Popup {
  _Popup(
    this.windowUrl,
    this.windowName,
    this.loginCallback,
    this.popupBlockedCallback,
  );

  final String windowUrl;
  final String windowName;
  final Future<void> Function(String data) loginCallback;
  final void Function()? popupBlockedCallback;
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final transfers = <TransferInfo>[];
  final popups = <_Popup>[];

  /// Stands in for `webWindowWithCallback`: records the request so the test
  /// can drive the callback the browser would have driven.
  void fakeOpener(
    String windowUrl,
    String windowName, {
    required void Function() completerFutureCallback,
    required Future<void> Function(String) loginCallback,
    void Function()? popupBlockedCallback,
  }) {
    completerFutureCallback();
    popups.add(
      _Popup(windowUrl, windowName, loginCallback, popupBlockedCallback),
    );
  }

  void stubSheet({int transferStatus = 200}) {
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
      () => scaffold.repository.mypaymentUsersMeWalletHistoryGet(),
    ).thenAnswer((_) async => chopper.Response(http.Response('body', 200), []));
    when(
      () => scaffold.repository.mypaymentTransferInitPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      if (transferStatus != 200) {
        return chopper.Response(
          http.Response('{"detail": "transfer down"}', transferStatus),
          null,
          error: 'transfer down',
        );
      }
      transfers.add(invocation.namedArguments[#body] as TransferInfo);
      return chopper.Response(
        http.Response('body', 200),
        PaymentUrl.empty().copyWith(url: 'https://helloasso.example/pay'),
      );
    });
    stubUrlLauncher(FakeUrlLauncher());
  }

  setUp(() {
    transfers.clear();
    popups.clear();
  });

  /// Mounts the button alone, at the amount the numeric pad would have
  /// produced, so the amount gate is already satisfied and the tap reaches the
  /// fund initialisation.
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    required bool isWeb,
  }) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    container.read(fundAmountProvider.notifier).setFundAmount('10');
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: ConfirmFundButton(isWeb: isWeb, openWindow: fakeOpener),
      ),
      container,
      // The HelloAsso row overflows the 360px harness font (convention 20);
      // this file is about the web branches, not the layout.
      surface: const ui.Size(560, 1000),
    );
    await settle(tester, frames: 20);
    return container;
  }

  testWidgets('on the web the top-up redirects back to the site, opens the '
      'popup and clears the amount', (tester) async {
    stubSheet();
    final container = await mount(tester, isWeb: true);

    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    expect(transfers, hasLength(1));
    expect(transfers.single.amount, 1000);
    // The web redirect has to be an https page on the site, not the
    // `scheme://mypayment` deep link the app build returns to: HelloAsso
    // navigates the browser here, and only the site can hand control back.
    expect(transfers.single.redirectUrl, '${getTitanURL()}/mypayment');
    expect(popups, hasLength(1));
    expect(popups.single.windowName, 'HelloAsso');
    expect(popups.single.windowUrl, 'https://helloasso.example/pay');
    expect(container.read(fundAmountProvider), isEmpty);
    await scaffold.drainToast(tester);
  });

  testWidgets('a completed round-trip reports success and refreshes the '
      'wallet and the history', (tester) async {
    stubSheet();
    await mount(tester, isWeb: true);

    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);
    expect(popups, hasLength(1));

    // What the browser posts back once HelloAsso finished: the callback is
    // read for `code`, and only `succeeded` counts as a payment.
    clearInteractions(scaffold.repository);
    await popups.single.loginCallback(
      'https://myemapp.com/static.html?code=succeeded',
    );
    await settle(tester, frames: 20);

    expect(find.text('Payment completed successfully'), findsOneWidget);
    // The balance shown by the sheet comes from the wallet provider, so a
    // payment that did not reload it leaves a stale balance on screen.
    verify(() => scaffold.repository.mypaymentUsersMeWalletGet())
        .called(greaterThanOrEqualTo(1));
    verify(() => scaffold.repository.mypaymentUsersMeWalletHistoryGet())
        .called(greaterThanOrEqualTo(1));
    await scaffold.drainToast(tester);
  });

  testWidgets(
    'a cancelled round-trip reports the cancellation, not a success',
    (tester) async {
      stubSheet();
      await mount(tester, isWeb: true);

      await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
      await settle(tester, frames: 20);

      // HelloAsso answers with anything other than `code=succeeded` when the
      // user backs out of the payment page.
      await popups.single.loginCallback(
        'https://myemapp.com/static.html?code=cancelled',
      );
      await settle(tester, frames: 20);

      expect(find.text('Payment cancelled'), findsOneWidget);
      expect(find.text('Payment completed successfully'), findsNothing);
      await scaffold.drainToast(tester);
    },
  );

  testWidgets('a blocked popup is reported instead of dropping the top-up '
      'silently', (tester) async {
    stubSheet();
    await mount(tester, isWeb: true);

    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    // Browsers refuse `window.open` outside a user gesture; the shim calls
    // this callback instead of opening anything.
    popups.single.popupBlockedCallback!();
    await settle(tester, frames: 20);

    expect(find.text('Please allow popups'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused transfer initialisation surfaces the backend error', (
    tester,
  ) async {
    stubSheet(transferStatus: 500);
    final container = await mount(tester, isWeb: true);

    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);

    // The error arm of the provider answer: nothing was created, no popup was
    // opened, and the user is told why rather than left with a dead button.
    expect(find.text('transfer down'), findsOneWidget);
    expect(popups, isEmpty);
    // The amount stays: nothing was paid, so a retry must not re-type it.
    expect(container.read(fundAmountProvider), '10');
    await scaffold.drainToast(tester);
  });
}
