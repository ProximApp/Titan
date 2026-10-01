import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/tools/functions.dart';
import 'package:titan/mypayment/tools/key_service.dart';

import '../../shared/app_scaffold.dart';

/// Unit coverage for `lib/mypayment/tools/functions.dart` (its largest
/// uncovered block): device status tags/ordering, transfer-type mapping,
/// the seeded color engine, transaction palette selection and the payment
/// request expiry check. The scan QR builder runs through a fake KeyService
/// (the real one reads secure storage and does Ed25519 signing).
class _FakeKeyPair extends Fake implements SimpleKeyPair {}

class _FakeKeyServiceForScan extends Fake implements KeyService {
  @override
  Future<String?> getKeyId() async => 'key-id-1';

  @override
  Future<SimpleKeyPair?> getKeyPair() async => _FakeKeyPair();

  @override
  Future<Signature> signMessage(
    SimpleKeyPair keyPair,
    List<int> message,
  ) async => Signature(
    List.filled(64, 7),
    publicKey: SimplePublicKey(const [1], type: KeyPairType.ed25519),
  );
}

void main() {
  group('getStatusTag', () {
    testWidgets('renders a colored label per device status', (tester) async {
      Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

      await tester.pumpWidget(
        wrap(getStatusTag(enums.WalletDeviceStatus.active)),
      );
      await tester.pump();
      expect(find.text('Actif'), findsOneWidget);

      await tester.pumpWidget(
        wrap(getStatusTag(enums.WalletDeviceStatus.inactive)),
      );
      await tester.pump();
      expect(find.text('Inactif'), findsOneWidget);

      await tester.pumpWidget(
        wrap(getStatusTag(enums.WalletDeviceStatus.revoked)),
      );
      await tester.pump();
      expect(find.text('Désactivé'), findsOneWidget);

      // The unknown status renders an empty container.
      await tester.pumpWidget(
        wrap(getStatusTag(enums.WalletDeviceStatus.swaggerGeneratedUnknown)),
      );
      await tester.pump();
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });
  });

  group('transfer type mapping', () {
    test('round-trips every transfer type', () {
      for (final type in TransferType.values) {
        expect(transferTypeFromString(transferTypeToString(type)), type);
      }
    });

    test('maps the wire strings exactly', () {
      expect(transferTypeToString(TransferType.bankTransfer), 'bank_transfer');
      expect(transferTypeToString(TransferType.helloAsso), 'hello_asso');
      expect(transferTypeToString(TransferType.cash), 'cash');
      expect(transferTypeToString(TransferType.check), 'check');
    });

    test('falls back to helloAsso on unknown input', () {
      expect(transferTypeFromString('nonsense'), TransferType.helloAsso);
    });
  });

  test('statusOrder ranks active before inactive before revoked', () {
    expect(
      statusOrder(enums.WalletDeviceStatus.active),
      lessThan(statusOrder(enums.WalletDeviceStatus.inactive)),
    );
    expect(
      statusOrder(enums.WalletDeviceStatus.inactive),
      lessThan(statusOrder(enums.WalletDeviceStatus.revoked)),
    );
    expect(statusOrder(enums.WalletDeviceStatus.swaggerGeneratedUnknown), 3);
  });

  group('generateColorVariations', () {
    const base = [Color(0xFF017F80), Color(0xFF006667)];

    test('is deterministic for the same seed', () {
      expect(
        generateColorVariations(base, 'store-1'),
        generateColorVariations(base, 'store-1'),
      );
    });

    test('keeps the alpha of every base color', () {
      const withAlpha = [Color(0xAA112233), Color(0x55445566)];
      final result = generateColorVariations(withAlpha, 'seed');
      expect(result[0].a, withAlpha[0].a);
      expect(result[1].a, withAlpha[1].a);
    });

    test('stays within the clamp bounds and damps later colors', () {
      final colors = List.generate(6, (i) => const Color(0xFF808080));
      final result = generateColorVariations(colors, 'extreme');
      for (final color in result) {
        expect(color.r, inInclusiveRange(0, 1));
        expect(color.g, inInclusiveRange(0, 1));
        expect(color.b, inInclusiveRange(0, 1));
      }
      // Damping: later colors move less than the first one.
      double delta(Color a, Color b) =>
          ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs());
      expect(
        delta(colors.last, result.last),
        lessThanOrEqualTo(delta(colors[0], result[0])),
      );
    });
  });

  test('getTransactionColors returns a palette per history type', () {
    for (final type in enums.HistoryType.values) {
      final transaction = history(
        'h-1',
        enums.HistoryDirection.credited,
        100,
      ).copyWith(type: type);
      expect(getTransactionColors(transaction), hasLength(3));
    }
  });

  group('isRequestExpired', () {
    Request$ request(DateTime expiration) => Request$(
      id: 'r-1',
      walletId: 'w-1',
      creation: DateTime(2026),
      expirationDate: expiration,
      total: 100,
      storeId: 's-1',
      name: 'Café',
      module: 'mypayment',
      objectId: 'o-1',
      status: enums.RequestStatus.proposed,
    );

    test('is expired when the expiration date has passed', () {
      expect(
        isRequestExpired(
          request(DateTime.now().subtract(const Duration(hours: 1))),
        ),
        isTrue,
      );
    });

    test('is not expired while the date is in the future', () {
      expect(
        isRequestExpired(request(DateTime.now().add(const Duration(hours: 1)))),
        isFalse,
      );
    });
  });

  test('getQRCodeContent builds a signed ScanInfo envelope', () async {
    final json = await getQRCodeContent(
      'seller-1',
      '4,50',
      _FakeKeyServiceForScan(),
      true,
    );
    final scan = ScanInfo.fromJson(
      Map<String, dynamic>.from(jsonDecode(json) as Map<String, dynamic>),
    );
    expect(scan.id, 'seller-1');
    // The comma-decimal string converts to integer cents.
    expect(scan.tot, 450);
    expect(scan.key, 'key-id-1');
    expect(scan.store, isTrue);
    expect(scan.signature, isNotEmpty);
  });
}
