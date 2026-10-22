import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

WalletDevice device(String id, String name, WalletDeviceStatus status) =>
    WalletDevice.empty().copyWith(
      id: id,
      name: name,
      walletId: 'wallet-1',
      creation: DateTime(2026, 1, 5),
      status: status,
    );

void stubMyPayment(
  IntegrationScaffold scaffold, {
  List<WalletDevice>? devices,
}) {
  when(
    () => scaffold.repository.mypaymentUsersMeWalletDevicesGet(),
  ).thenAnswer((_) async => chopperListResponse(devices ?? <WalletDevice>[]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('devices page lists the registered devices with their status', (
    tester,
  ) async {
    stubMyPayment(
      scaffold,
      devices: [device('dev-1', 'iPhone 15', WalletDeviceStatus.active)],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/devices',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('iPhone 15'), findsOneWidget);
    // Status tags are hardcoded in the app (fr).
    expect(find.text('Actif'), findsOneWidget);
  });

  testWidgets('devices page renders the header with no device registered', (
    tester,
  ) async {
    stubMyPayment(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/devices',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // No device: only the add-device button is rendered.
    expect(find.text('Add this device'), findsOneWidget);
    expect(find.text('Actif'), findsNothing);
  });
}
