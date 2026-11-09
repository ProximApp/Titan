import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/device_provider.dart';
import 'package:titan/mypayment/providers/pay_amount_provider.dart';
import 'package:titan/mypayment/ui/pages/main_page/account_card/device_dialog_box.dart';
import 'package:titan/mypayment/ui/pages/pay_page/pay_page.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

/// The wallet account card's action buttons on the real payment page.
///
/// Every one of them is a `MainCardButton` whose tap target is the 40px
/// rounded icon (not its label, and not the enclosing column): the widget
/// file seals only the card's layout arms, so nothing had ever pressed them.
/// Here the five actions are pressed for real:
///
/// * Devices → invalidates the device list and routes to it (the file's single
///   navigation journey, asserted first per convention 10),
/// * Pay → the three device states the wallet can answer with (active opens
///   the pay sheet, inactive and revoked open their own dialog), the missing
///   key dialog, and the pay sheet's close callback resetting the amount,
/// * Stats and Request history → their own routes, asserted through the
///   observable route the button asked for.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The pay button is the QR icon, the devices button the phone icon; both
  /// are `WaitingButton`s whose tap target is that icon alone.
  Finder iconButton(HeroIcons icon) =>
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == icon);

  Future<ProviderContainer> bootPaymentPage(
    WidgetTester tester, {
    String? deviceKeyId = 'device-1',
    List<dynamic> providerOverrides = const [],
  }) async {
    stubMainPage(scaffold);
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      deviceKeyId: deviceKeyId,
      providerOverrides: providerOverrides,
    );
    addTearDown(container.dispose);
    await scaffold.pumpApp(tester, container, initialPath: '/mypayment');
    await settle(tester, frames: 16);
    return container;
  }

  testWidgets('the Devices button invalidates the list and routes to it', (
    tester,
  ) async {
    await bootPaymentPage(tester);

    await tester.tap(
      iconButton(HeroIcons.devicePhoneMobile),
      warnIfMissed: false,
    );
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/mypayment/devices');
  });

  testWidgets('the request-history button routes to the activity page', (
    tester,
  ) async {
    stubUsedRequests(scaffold, requests: []);
    await bootPaymentPage(tester);

    await tester.tap(iconButton(HeroIcons.listBullet), warnIfMissed: false);
    await settle(tester, frames: 20);

    expect(QR.currentPath, '/mypayment/requestHistory');
    expect(find.text('Activities'), findsOneWidget);
  });

  testWidgets(
    'an active device opens the pay sheet and closing it clears the amount',
    (tester) async {
      final container = await bootPaymentPage(tester);
      stubWalletDevice(scaffold, WalletDeviceStatus.active);
      container.read(payAmountProvider.notifier).setPayAmount('12');
      await settle(tester, frames: 4);

      await tester.tap(iconButton(HeroIcons.qrCode), warnIfMissed: false);
      await settle(tester, frames: 20);

      expect(find.byType(PayPage), findsOneWidget);

      // The sheet's onCloseCallback clears the typed amount, so a reopened
      // sheet never starts from the previous payment's total.
      await tester.tapAt(const Offset(6, 6));
      await settle(tester, frames: 20);

      expect(container.read(payAmountProvider), '');
    },
  );

  testWidgets('an inactive device explains itself before any payment', (
    tester,
  ) async {
    await bootPaymentPage(tester);
    stubWalletDevice(scaffold, WalletDeviceStatus.inactive);

    await tester.tap(iconButton(HeroIcons.qrCode), warnIfMissed: false);
    await settle(tester, frames: 20);

    expect(find.byType(DeviceDialogBox), findsOneWidget);
    expect(find.text('Device not activated'), findsOneWidget);
    expect(find.byType(PayPage), findsNothing);

    // The dialog's button sends the user to the devices page and pops itself.
    await tester.tap(find.text('Access the page'));
    await settle(tester, frames: 20);

    expect(find.byType(DeviceDialogBox), findsNothing);
  });

  testWidgets('a revoked device explains itself before any payment', (
    tester,
  ) async {
    await bootPaymentPage(tester);
    stubWalletDevice(scaffold, WalletDeviceStatus.revoked);

    await tester.tap(iconButton(HeroIcons.qrCode), warnIfMissed: false);
    await settle(tester, frames: 20);

    expect(find.text('Device revoked'), findsOneWidget);
    expect(find.byType(PayPage), findsNothing);

    await tester.tap(find.text('Access the page'));
    await settle(tester, frames: 20);

    expect(find.byType(DeviceDialogBox), findsNothing);
  });

  testWidgets('no registered key explains how to register one', (tester) async {
    await bootPaymentPage(tester, deviceKeyId: null);

    await tester.tap(iconButton(HeroIcons.qrCode), warnIfMissed: false);
    await settle(tester, frames: 20);

    expect(find.text('Device not registered'), findsOneWidget);

    await tester.tap(find.text('Access the page'));
    await settle(tester, frames: 20);

    expect(find.byType(DeviceDialogBox), findsNothing);
  });

  testWidgets('a device read that never answers opens nothing', (tester) async {
    // The card's `loading` arm: `getDevice` always answers a settled
    // AsyncValue (data for every HTTP reply, a throw for a transport
    // failure), so no stubbed endpoint can hold it pending. It is what the
    // user sees during the round-trip, though — and the arm must stay silent
    // rather than guess a device state: no pay sheet, no "not activated"
    // dialog, and no error toast for a read that has not failed.
    await bootPaymentPage(
      tester,
      providerOverrides: [
        deviceProvider.overrideWith(
          () => FakeDeviceNotifier(const AsyncValue.loading()),
        ),
      ],
    );

    await tester.tap(iconButton(HeroIcons.qrCode), warnIfMissed: false);
    await settle(tester, frames: 20);

    expect(find.byType(PayPage), findsNothing);
    expect(find.byType(DeviceDialogBox), findsNothing);
    expect(anyVisibleTextContains(tester, 'Error'), isFalse);
    expect(QR.currentPath, '/mypayment');
  });
}
