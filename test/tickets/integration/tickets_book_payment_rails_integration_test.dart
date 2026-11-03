import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';

import '../../shared/app_scaffold.dart';

/// The myempay rail on `/tickets/book`: every `CanPayError` arm the tile
/// renders a reason for, plus the auto-switch that takes the user back to
/// HelloAsso when myempay stops being payable.
///
/// `canPayProvider` is a real provider reading the real TOS chain and the
/// real wallet-device endpoint, so each reason is produced by seeding the
/// backend answers that provokes it — not by overriding the provider. The
/// three things the chain branches on are: whether the accepted TOS version
/// equals the latest, whether this install has a key id, and the status the
/// backend reports for that device.
///
/// The balance arm is different in kind: `canPayProvider` deliberately
/// excludes the balance (it depends on the amount), so the page compares it
/// against the selected category's price itself. That comparison is what
/// makes the tile unselectable AND what flips the selection back to
/// HelloAsso afterwards.
EventPublic bookableEvent() => EventPublic.empty().copyWith(
  id: 'evt-1',
  name: 'Gala 2026',
  categories: [
    CategoryPublic.empty().copyWith(id: 'cat-1', name: 'Normal', price: 1000),
    CategoryPublic.empty().copyWith(id: 'cat-2', name: 'Premium', price: 2500),
  ],
  sessions: [
    SessionPublic.empty().copyWith(
      id: 'ses-1',
      name: 'Saturday',
      startDatetime: DateTime(2026, 1, 11, 20),
    ),
  ],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The HelloAsso tile is the default selection, so this warning is present
  /// exactly while HelloAsso is the selected method — which makes it the
  /// observable form of "myempay did (not) get selected".
  const helloAssoSelected =
      'The payment link is personal and must not be '
      'shared.';

  /// Seeds the readiness chain. [accepted] is what the accepted/latest pair
  /// compares equal to; [deviceStatus] is what the backend reports for the
  /// registered device (pass null to answer with an unknown device);
  /// [balance] is the wallet's balance in cents.
  void stubPaymentChain({
    bool accepted = true,
    String? deviceKeyId = 'key-1',
    enums.WalletDeviceStatus? deviceStatus = enums.WalletDeviceStatus.active,
    int balance = 0,
  }) {
    final version = accepted ? 1 : 0;
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopperResponse(
        TOSSignatureResponse.empty().copyWith(
          acceptedTosVersion: version,
          latestTosVersion: 1,
        ),
      ),
    );
    when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
      (_) async => chopperResponse(Wallet.empty().copyWith(balance: balance)),
    );
    // A null status stands for a device the backend has no record of: the
    // lookup itself fails, which is the branch `canPayProvider` reads as
    // "never registered".
    when(
      () => scaffold.repository.mypaymentUsersMeWalletDevicesWalletDeviceIdGet(
        walletDeviceId: any(named: 'walletDeviceId'),
      ),
    ).thenAnswer(
      (_) async => deviceStatus == null
          ? chopper.Response<WalletDevice>(
              http.Response('{"detail": "Device not found"}', 404),
              null,
              error: 'Device not found',
            )
          : chopperResponse(
              WalletDevice.empty().copyWith(
                id: deviceKeyId,
                status: deviceStatus,
              ),
            ),
    );
    when(() => scaffold.repository.ticketsUserMeTicketsGet()).thenAnswer(
      (_) async =>
          chopperListResponse<AppCoreTicketsSchemasTicketsTicketComplete>([]),
    );
    when(() => scaffold.repository.ticketsEventsEventIdGet(eventId: 'evt-1'))
        .thenAnswer((_) async => chopperResponse(bookableEvent()));
  }

  Future<void> pumpBook(
    WidgetTester tester, {
    String? deviceKeyId = 'key-1',
  }) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(deviceKeyId: deviceKeyId);
    addTearDown(container.dispose);
    container
        .read(pathForwardingProvider.notifier)
        .forward('/tickets/book', queryParameters: {'ticketEventId': 'evt-1'});

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/book',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
  }

  /// Picks a category, which is what reveals the payment tiles at all — before
  /// a category is chosen the page renders neither the total nor the methods.
  Future<void> pickCategory(WidgetTester tester, String name) async {
    await tester.ensureVisible(find.text(name));
    await tester.tap(find.text(name));
    await settle(tester, frames: 12);
  }

  testWidgets('myempay reports unaccepted terms and keeps HelloAsso selected', (
    tester,
  ) async {
    stubPaymentChain(accepted: false);
    await pumpBook(tester);
    await pickCategory(tester, 'Normal');

    expect(find.text('myempay'), findsOneWidget);
    expect(find.text('Please accept the Terms of Service.'), findsOneWidget);
    // A disabled tile is not a selectable one: tapping it changes nothing.
    await tester.tap(find.text('myempay'));
    await settle(tester, frames: 4);
    expect(find.text(helloAssoSelected), findsOneWidget);
  });

  testWidgets('an inactive device names the activation step', (tester) async {
    stubPaymentChain(deviceStatus: enums.WalletDeviceStatus.inactive);
    await pumpBook(tester);
    await pickCategory(tester, 'Normal');

    expect(find.text('Device not activated'), findsOneWidget);
    // The TOS were accepted and a key exists, so neither of those reasons
    // may appear — this pins the switch arms apart from each other.
    expect(find.text('Please accept the Terms of Service.'), findsNothing);
    expect(find.text('Device not registered'), findsNothing);
  });

  testWidgets('a revoked device names revocation', (tester) async {
    stubPaymentChain(deviceStatus: enums.WalletDeviceStatus.revoked);
    await pumpBook(tester);
    await pickCategory(tester, 'Normal');

    expect(find.text('Device revoked'), findsOneWidget);
    expect(find.text('Device not activated'), findsNothing);
  });

  testWidgets('a device the backend does not know reads as not registered', (
    tester,
  ) async {
    // The key id exists locally but the wallet lookup answers with nothing:
    // the provider maps that to the same reason as never having registered.
    stubPaymentChain(deviceStatus: null);
    await pumpBook(tester);
    await pickCategory(tester, 'Normal');

    expect(find.text('Device not registered'), findsOneWidget);
  });

  testWidgets('a balance below the price reports insufficient funds', (
    tester,
  ) async {
    stubPaymentChain(balance: 0);
    await pumpBook(tester);
    await pickCategory(tester, 'Normal');

    // The device IS payable here — only the amount is out of reach, which
    // is the arm the provider deliberately leaves to the page.
    expect(find.text('Insufficient Funds'), findsOneWidget);
    expect(find.text('Device not registered'), findsNothing);
    await tester.tap(find.text('myempay'));
    await settle(tester, frames: 4);
    expect(find.text(helloAssoSelected), findsOneWidget);
  });

  testWidgets(
    'raising the price past the balance switches the selection back to '
    'HelloAsso',
    (tester) async {
      // A wallet that covers the cheap category but not the expensive one.
      stubPaymentChain(balance: 1000);
      await pumpBook(tester);
      await pickCategory(tester, 'Normal');

      // 1000 >= 1000, so myempay is genuinely selectable...
      expect(find.text('Insufficient Funds'), findsNothing);
      await tester.tap(find.text('myempay'));
      await settle(tester, frames: 4);
      expect(
        find.text(helloAssoSelected),
        findsNothing,
        reason: 'tapping the myempay tile must select it',
      );

      // ...until the price exceeds the balance, at which point the page
      // moves the selection off a method that can no longer pay.
      await pickCategory(tester, 'Premium');

      expect(find.text('Insufficient Funds'), findsOneWidget);
      expect(
        find.text(helloAssoSelected),
        findsOneWidget,
        reason:
            'the auto-switch exists so the user is never left on a payment '
            'method that cannot go through',
      );
    },
  );
}
