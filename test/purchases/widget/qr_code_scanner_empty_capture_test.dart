import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/purchases/ui/pages/scan_page/qr_code_scanner.dart';

import '../../shared/app_scaffold.dart';

/// The scanner's `onDetect` must ignore the frames the camera really emits:
/// a capture with no decoded barcode, and a barcode with no raw value both
/// used to throw (`Bad state: No element` and a null-check) inside the scan
/// page, where nothing catches them.
void main() {
  late IntegrationScaffold scaffold;
  late FakeMobileScannerPlatform fakePlatform;
  MobileScannerPlatform? previousPlatform;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    previousPlatform = MobileScannerPlatform.instance;
    fakePlatform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fakePlatform;
  });

  tearDown(() {
    MobileScannerPlatform.instance = previousPlatform!;
  });

  testWidgets('empty and valueless captures are ignored, a payload scans', (
    tester,
  ) async {
    final scanned = <String>[];
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      QRCodeScannerScreen(
        onScan: scanned.add,
        scanner: AsyncValue.data(AppModulesCdrSchemasCdrTicket.empty()),
      ),
      container,
    );

    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    final onDetect = scanner.onDetect!;

    // No barcode in the frame at all.
    onDetect(const BarcodeCapture());
    await tester.pump();
    expect(scanned, isEmpty);

    // A barcode the decoder could not read.
    onDetect(const BarcodeCapture(barcodes: [Barcode()]));
    await tester.pump();
    expect(scanned, isEmpty);

    // A real payload still reaches the caller.
    onDetect(const BarcodeCapture(barcodes: [Barcode(rawValue: 'PAYLOAD')]));
    await tester.pump();
    expect(scanned, ['PAYLOAD']);
  });
}
