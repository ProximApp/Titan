import 'package:flutter_test/flutter_test.dart';

import '../mypayment_fixtures.dart';
import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('devices page lists the registered devices with their status', (
    tester,
  ) async {
    stubDevices(scaffold, devices: [device('dev-1', 'iPhone 15')]);

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
    stubDevices(scaffold);

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
