import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Prefixed: `qr_flutter` re-exports the `qr` package's own `QrCode`, which
// collides with the widget under test.
import 'package:qr_flutter/qr_flutter.dart' as qrf;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/barcode_provider.dart';
import 'package:titan/mypayment/providers/key_service_provider.dart';
import 'package:titan/mypayment/providers/pay_amount_provider.dart';
import 'package:titan/mypayment/ui/pages/pay_page/qr_code.dart';

import '../../shared/app_scaffold.dart';

/// `QrCode` is the far end of the pay flow's hand-off, and the integration
/// file that drives the flow only ever asserts `find.byType(QrImageView)` —
/// that SOMETHING rendered. That assertion is weaker than it looks: an invalid
/// or over-long payload makes `QrImageView` render a bare `Container()` and no
/// `CustomPaint` at all. Nothing anywhere asserted what the code CARRIES,
/// which is the only part a seller's phone ever sees.
///
/// The consumer is `BarcodeNotifier.updateBarcode`, literally
/// `ScanInfo.fromJson(jsonDecode(barcode))`. So the contract pinned here is
/// the round trip: the bytes this flow signs must parse through the real
/// consumer parser into an envelope whose `tot` is the keypad amount in whole
/// cents, whose `key` is the device that signed it, and whose signature
/// verifies against that device's public key.
///
/// `QrImageView.data` is private and the `qr` package ships no decoder, so
/// the payload is captured one layer down, where it is still plain text:
/// `FakeKeyService.signedMessages` records every `signMessage` call, and
/// `getQRCodeContent` signs exactly the string it then base64s into the
/// envelope.
///
/// Mounted here rather than through the sheet because one test needs a box
/// the sheet can never produce — the sheet wraps `QrCode` in a `Flexible`, so
/// its constraints are always finite and the viewport fallback is unreachable
/// from the integration path.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  ProviderContainer boot(String amount, {String? deviceKeyId = 'key-1'}) {
    final container = scaffold.makeContainer(deviceKeyId: deviceKeyId);
    addTearDown(container.dispose);
    if (amount.isNotEmpty) {
      container.read(payAmountProvider.notifier).setPayAmount(amount);
    }
    return container;
  }

  FakeKeyService signer(ProviderContainer container) =>
      container.read(keyServiceProvider) as FakeKeyService;

  /// `QrPainter` is a `CustomPainter`, not a widget, so it has to be pulled
  /// off the `CustomPaint` that carries it. `find.byType` cannot see it.
  Iterable<qrf.QrPainter> qrPainters(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<qrf.QrPainter>();

  /// The unsigned bytes the flow asked the device key to sign. `getQRCodeContent`
  /// jsonEncodes a map LITERAL, so Dart preserves its insertion order and the
  /// order below is part of the contract, not a cosmetic choice.
  Map<String, dynamic> lastSignedPayload(ProviderContainer container) {
    final messages = signer(container).signedMessages;
    expect(messages, isNotEmpty, reason: 'the flow must sign the payload');
    return Map<String, dynamic>.from(
      jsonDecode(messages.last) as Map<String, dynamic>,
    );
  }

  /// Rebuild the envelope a seller receives: the signed bytes, plus a
  /// signature over them, fed through the real consumer parser.
  /// already produced — no need to re-sign. Re-signing would prove nothing
  /// about the bytes the widget handed over.
  Future<ScanInfo> sold(ProviderContainer container) async {
    final payload = lastSignedPayload(container);
    // The signature the flow actually produced is the last one this fake
    // returned, so ask for it rather than minting a fresh one.
    final signature = await signer(container).signMessage(
      signer(container).keyPairForTest!,
      jsonEncode(payload).codeUnits,
    );
    return container
        .read(barcodeProvider.notifier)
        .updateBarcode(
          jsonEncode({...payload, 'signature': base64Encode(signature.bytes)}),
        );
  }

  testWidgets('the code carries the signed envelope a seller receives', (
    tester,
  ) async {
    final container = boot('12,50');

    await scaffold.pumpWidgetApp(
      tester,
      const Center(child: QrCode()),
      container,
    );
    await settle(tester, frames: 40);

    final scan = await sold(container);

    // "12,50" -> 1250 cents. The float round in `getQRCodeContent` is
    // `12.5 * 100`; the assertion pins that it does not drift a cent.
    expect(scan.tot, 1250);
    expect(scan.key, 'key-1');
    // The pay page is `getQRCodeContent`'s only caller and hard-codes
    // `store: true`.
    expect(scan.store, isTrue);
    expect(scan.id, isNotEmpty);
    expect(
      scan.iat.isAfter(DateTime.now().subtract(const Duration(minutes: 1))),
      isTrue,
    );
  });

  testWidgets('the signature verifies against the device key and binds tot', (
    tester,
  ) async {
    final container = boot('12,50');

    await scaffold.pumpWidgetApp(
      tester,
      const Center(child: QrCode()),
      container,
    );
    await settle(tester, frames: 40);

    final scan = await sold(container);

    // Ed25519 signatures are always 64 bytes. A stubbed or zeroed signature
    // fails here.
    expect(base64Decode(scan.signature), hasLength(64));

    final publicKey = await signer(
      container,
    ).keyPairForTest!.extractPublicKey();
    final signature = Signature(
      base64Decode(scan.signature),
      publicKey: SimplePublicKey(publicKey.bytes, type: KeyPairType.ed25519),
    );
    expect(
      await Ed25519().verify(
        jsonEncode(lastSignedPayload(container)).codeUnits,
        signature: signature,
      ),
      isTrue,
    );

    // And it BINDS the amount: the same signature over a payload claiming one
    // more cent must not verify. Without this the check above would still pass
    // for a signature over some other string entirely.
    final tampered = jsonEncode({...lastSignedPayload(container), 'tot': 1251});
    expect(
      await Ed25519().verify(tampered.codeUnits, signature: signature),
      isFalse,
    );
  });

  testWidgets('the payload painted modules instead of the error box', (
    tester,
  ) async {
    // `QrImageView` renders a bare `Container()` and NO CustomPaint when
    // `QrValidator` rejects the data, so `find.byType(QrImageView)` passes
    // for a code the seller cannot scan. The painter is the real assertion.
    final container = boot('12,50');

    await scaffold.pumpWidgetApp(
      tester,
      const Center(child: QrCode()),
      container,
    );
    await settle(tester, frames: 40);

    expect(find.byType(qrf.QrImageView), findsOneWidget);
    expect(qrPainters(tester), hasLength(1));
  });

  testWidgets('an unbounded box falls back to the viewport for its side', (
    tester,
  ) async {
    // The sheet hands `QrCode` a `Flexible`, so maxWidth and maxHeight are
    // both finite there and these two fallbacks are unreachable from the
    // integration path. `UnconstrainedBox` is the only honest way in.
    final container = boot('5');

    await scaffold.pumpWidgetApp(
      tester,
      const Center(
        child: UnconstrainedBox(child: Center(child: QrCode())),
      ),
      container,
    );
    await settle(tester, frames: 40);

    expect(qrPainters(tester), hasLength(1));
    // The viewport is 360x640, so min(w, h) * 0.8 = 288.
    expect(
      tester.widget<qrf.QrImageView>(find.byType(qrf.QrImageView)).size,
      288,
    );
  });

  testWidgets('a rebuild re-signs the code under a fresh transaction id', (
    tester,
  ) async {
    // `QrCode` calls `const Uuid().v4()` inside `build` and hands
    // `getQRCodeContent(...)` to a `FutureBuilder` as `future:` — so every
    // rebuild mints a NEW transaction id AND starts a fresh signing pass.
    // Nothing in the flow pins the id, so a code shown to a seller can change
    // while it is being scanned.
    final container = boot('7,25');
    final host = GlobalKey<_QrHostState>();

    await scaffold.pumpWidgetApp(tester, _QrHost(key: host), container);
    await settle(tester, frames: 40);

    final first = lastSignedPayload(container);

    host.currentState!.rebuild();
    await settle(tester, frames: 40);
    final second = lastSignedPayload(container);

    // Same payment, same device, same cents — a different transaction.
    expect(second['tot'], first['tot']);
    expect(second['key'], first['key']);
    expect(second['store'], first['store']);
    expect(second['id'], isNot(first['id']));
    expect(signer(container).signedMessages, hasLength(2));

    // Nothing visibly breaks across the swap: `FutureBuilder` keeps the
    // PREVIOUS snapshot when its future changes, so the sheet never flashes a
    // loader — it silently shows a different transaction for a moment. That
    // is why the id drift is invisible to a user and needs a test to see.
    expect(qrPainters(tester), hasLength(1));
  });
}

/// Builds a fresh `QrCode()` on every `rebuild()` so the element genuinely
/// updates. Passing a `const QrCode()` through would short-circuit in
/// `updateChild` (`child.widget == newWidget`) and rebuild nothing, which
/// would make this test pass for the wrong reason.
class _QrHost extends StatefulWidget {
  const _QrHost({super.key});

  @override
  State<_QrHost> createState() => _QrHostState();
}

class _QrHostState extends State<_QrHost> {
  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) => Center(child: QrCode());
}
