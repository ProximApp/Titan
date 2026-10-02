import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/ui/components/digit_fade_in_animation.dart';
import 'package:titan/mypayment/ui/components/keyboard.dart';
import 'package:titan/mypayment/ui/pages/fund_page/confirm_button.dart';
import 'package:titan/mypayment/ui/pages/fund_page/fund_page.dart';
import 'package:titan/mypayment/ui/pages/main_page/main_card_button.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../shared/app_scaffold.dart';

/// The top-up flow: `fund_page.dart` (54 lines) and its `confirm_button.dart`
/// (80) sat at zero coverage between them, and they are the same shape as the
/// pay flow's two files with two differences that matter to the test design:
/// there is no biometric or device to satisfy, and the happy path LEAVES the
/// app — it POSTs a `TransferInfo` and hands the returned HelloAsso URL to
/// `launchUrl`.
///
/// That last part is why this file is worth having on its own. `FakeUrlLauncher`
/// records the URL, so the happy path can be asserted as "the app really asked
/// the system to open the provider's page" rather than "a button turned white".
///
/// Every guard is asserted through observable state instead of through its
/// toast: `toastification.show` renders into an overlay the `find`ers never
/// reach in this harness (convention 25), so a test that looked for the
/// message text would pass vacuously. What each guard actually guarantees is
/// that NO transfer was requested, and that is checkable.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  // 50,00 held, so the cap boundary is at 1000,00 - 50,00 = 950,00. That
  // offset is the whole point of the max check: it adds the CURRENT balance to
  // the typed amount, so the two tests below straddle it exactly.
  const balance = 5000;
  const maxWalletBalance = 100000;

  Wallet walletWith(int amount) =>
      Wallet.empty().copyWith(id: 'wallet-1', balance: amount);

  PaymentUrl fundingUrl() =>
      PaymentUrl.empty().copyWith(url: 'https://helloasso.example/pay');

  /// Stubs the whole dashboard plus the funding POST.
  ///
  /// [transfers] is filled by the POST stub, so a test can assert not just
  /// that a transfer happened but what was in it.
  void stubFundFlow({
    int amount = balance,
    int cap = maxWalletBalance,
    bool tosAccepted = true,
    bool fundingUrlRefused = false,
    List<TransferInfo> transfers = const [],
    bool launchSucceeds = true,
  }) {
    when(
      () => scaffold.repository.mypaymentUsersMeWalletGet(),
    ).thenAnswer((_) async => chopperResponse(walletWith(amount)));
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopperResponse(
        TOSSignatureResponse.empty().copyWith(
          acceptedTosVersion: tosAccepted ? 1 : 0,
          latestTosVersion: 1,
          maxWalletBalance: cap,
        ),
      ),
    );
    when(
      () => scaffold.repository.mypaymentUsersMeStoresGet(),
    ).thenAnswer((_) async => chopperListResponse(<UserStore>[]));
    when(
      () => scaffold.repository.mypaymentRequestsGet(),
    ).thenAnswer((_) async => chopperListResponse(<Request$>[]));
    when(
      () => scaffold.repository.mypaymentStructuresGet(),
    ).thenAnswer((_) async => chopperListResponse(<Structure>[]));
    when(
      () => scaffold.repository.mypaymentUsersMeWalletHistoryGet(),
    ).thenAnswer((_) async => chopperListResponse(<History>[]));
    when(
      () => scaffold.repository.mypaymentTransferInitPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      transfers.add(invocation.namedArguments[#body] as TransferInfo);
      if (fundingUrlRefused) {
        return chopper.Response(
          http.Response('{"detail": "refused"}', 500),
          null,
          error: 'funding url refused',
        );
      }
      return chopperResponse(fundingUrl());
    });
    stubUrlLauncher(FakeUrlLauncher(launchSucceeds: launchSucceeds));
  }

  Future<void> boot(WidgetTester tester) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    await scaffold.pumpApp(tester, container, initialPath: '/mypayment');
    await settle(tester, frames: 20);
  }

  /// The card's action BUTTON, resolved from its label.
  ///
  /// `MainCardButton` renders the title as a sibling of the `WaitingButton`'s
  /// hit target, so tapping the label itself silently does nothing.
  Finder cardAction(String label) => find
      .ancestor(of: find.text(label), matching: find.byType(MainCardButton))
      .first;

  Future<void> tapTopUp(WidgetTester tester) async {
    final topUp = cardAction('Top-up');
    expect(topUp, findsOneWidget, reason: 'the account card must be mounted');
    await tester.tap(topUp, warnIfMissed: false);
    await settle(tester, frames: 12);
  }

  /// The sheet's "balance after top-up: X ʍ (max: Y ʍ)" subtitle.
  String subtitle(WidgetTester tester) =>
      tester.widget<Text>(find.textContaining('Balance after top-up:')).data!;

  /// The per-character amount display, which the keypad's own keys would
  /// otherwise be indistinguishable from.
  Finder digits(String value) => find.descendant(
    of: find.byType(DigitFadeInAnimation),
    matching: find.text(value),
  );

  Future<void> press(WidgetTester tester, String key) async {
    await tester.tap(find.text(key).last, warnIfMissed: false);
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byType(ConfirmFundButton), warnIfMissed: false);
    await settle(tester, frames: 20);
  }

  testWidgets('a declined TOS blocks the top-up sheet', (tester) async {
    // The card checks `hasAcceptedTosProvider` before opening the sheet. This
    // is only observable by the sheet NOT appearing, so it is paired with the
    // next test, which opens the very same sheet from the very same tap.
    stubFundFlow(tosAccepted: false);
    await boot(tester);

    expect(find.text('New Terms of Service'), findsOneWidget);
    await tester.tap(find.text('Decline'), warnIfMissed: false);
    await settle(tester, frames: 12);

    await tapTopUp(tester);

    expect(find.byType(FundPage), findsNothing);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });

  testWidgets('the sheet opens from a bare tap and prints the TOS cap', (
    tester,
  ) async {
    // No device gate: the account card asks for a key before the PAY sheet
    // only, so the top-up sheet is one tap away with no key registered.
    stubFundFlow();
    await boot(tester);
    await tapTopUp(tester);

    expect(find.byType(FundPage), findsOneWidget);
    expect(find.byType(NumericKeyboard), findsOneWidget);
    expect(find.byType(ConfirmFundButton), findsOneWidget);

    // The subtitle is built from the wallet AND the TOS response, which is
    // what proves both providers resolved: 50,00 held against a 1 000,00 cap.
    // The group separator is matched around because the fr locale uses a
    // narrow no-break space that no plain-space literal would hit.
    expect(subtitle(tester), contains('50,00'));
    expect(subtitle(tester), contains('000,00'));
    expect(subtitle(tester), contains('(max:'));

    // Nothing typed yet, so the amount row is empty and no currency symbol.
    expect(find.text(' ʍ'), findsNothing);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the keypad builds an amount and backspace erases a digit', (
    tester,
  ) async {
    stubFundFlow();
    await boot(tester);
    await tapTopUp(tester);

    await press(tester, '2');
    await press(tester, '0');
    expect(digits('2'), findsOneWidget);
    expect(digits('0'), findsOneWidget);
    // The symbol appears only once the amount is non-empty.
    expect(find.text(' ʍ'), findsOneWidget);

    // The backspace is a HeroIcon, not a Text, so it is matched by type.
    final backspace = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.backspace,
    );
    expect(backspace, findsOneWidget);
    await tester.tap(backspace, warnIfMissed: false);
    await tester.pump();

    // "20" -> "2", so the leading 2 survives and the 0 is gone.
    expect(digits('2'), findsOneWidget);
    expect(digits('0'), findsNothing);

    // Backspacing the last remaining digit empties the field entirely...
    await tester.tap(backspace, warnIfMissed: false);
    await tester.pump();
    expect(digits('2'), findsNothing);

    // ...and a comma on an EMPTY field seeds a leading zero, "0,". The same
    // key on a non-empty field just appends, which is why the field has to be
    // cleared first.
    await press(tester, ',');
    expect(digits('0'), findsOneWidget);
    expect(find.text(' ʍ'), findsOneWidget);
    await tester.tap(backspace, warnIfMissed: false);
    await tester.pump();
    expect(digits('0'), findsNothing);
    expect(find.text(' ʍ'), findsNothing);

    await scaffold.unmountApp(tester);
  });

  testWidgets('an empty amount is under the minimum and requests nothing', (
    tester,
  ) async {
    // `minValidFundAmount` compares the TYPED amount alone against 1, so it
    // refuses before the cap is ever consulted — even though 0,00 would sit
    // comfortably under the cap.
    final transfers = <TransferInfo>[];
    stubFundFlow(transfers: transfers);
    await boot(tester);
    await tapTopUp(tester);

    await confirm(tester);

    expect(transfers, isEmpty);
    expect(find.byType(FundPage), findsOneWidget);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });

  testWidgets('an amount that exactly fills the cap is accepted', (
    tester,
  ) async {
    // 950,00 typed + 50,00 held == the 1 000,00 cap, and the check is `<=`, so
    // the boundary itself goes through. The next test moves one digit up and
    // is refused, which is what proves the arithmetic includes the balance
    // rather than just the typed amount.
    final transfers = <TransferInfo>[];
    stubFundFlow(transfers: transfers);
    await boot(tester);
    await tapTopUp(tester);

    for (final key in ['9', '5', '0']) {
      await press(tester, key);
    }
    await confirm(tester);

    expect(transfers, hasLength(1));
    expect(transfers.single.amount, 95000);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });

  testWidgets('one digit past the cap requests nothing', (tester) async {
    final transfers = <TransferInfo>[];
    stubFundFlow(transfers: transfers);
    await boot(tester);
    await tapTopUp(tester);

    for (final key in ['9', '5', '1']) {
      await press(tester, key);
    }
    await confirm(tester);

    // 951,00 + 50,00 busts the 1 000,00 cap. Nothing is requested, and the
    // sheet stays open with the amount intact for correction.
    expect(transfers, isEmpty);
    expect(find.byType(FundPage), findsOneWidget);
    expect(digits('9'), findsOneWidget);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
  });

  testWidgets('a valid amount POSTs a TransferInfo and launches the url', (
    tester,
  ) async {
    final transfers = <TransferInfo>[];
    stubFundFlow(transfers: transfers);
    await boot(tester);
    await tapTopUp(tester);

    for (final key in ['2', '0']) {
      await press(tester, key);
    }
    await confirm(tester);

    expect(transfers, hasLength(1));
    // 20,00 typed is 2000 CENTS: the button converts units to cents itself.
    expect(transfers.single.amount, 2000);
    // The redirect is the app's own deep link, not a web URL, so the provider
    // can bounce the user back into the app after paying.
    expect(transfers.single.redirectUrl, endsWith('://mypayment'));

    // The happy path leaves the app for the provider's page.
    final launcher = UrlLauncherPlatform.instance as FakeUrlLauncher;
    expect(launcher.launched, ['https://helloasso.example/pay']);

    // The sheet is popped and the amount cleared on success.
    expect(find.byType(FundPage), findsNothing);
    await scaffold.unmountApp(tester);
  });

  testWidgets('a refused funding url leaves the sheet and the amount alone', (
    tester,
  ) async {
    // The error arm neither pops nor clears: the user keeps the amount they
    // typed so a retry does not start from zero.
    final transfers = <TransferInfo>[];
    stubFundFlow(transfers: transfers, fundingUrlRefused: true);
    await boot(tester);
    await tapTopUp(tester);

    for (final key in ['2', '0']) {
      await press(tester, key);
    }
    await confirm(tester);

    expect(transfers, hasLength(1));
    expect(find.byType(FundPage), findsOneWidget);
    expect(digits('2'), findsOneWidget);
    expect((UrlLauncherPlatform.instance as FakeUrlLauncher).launched, isEmpty);
    await scaffold.drainToast(tester);
  });
}
