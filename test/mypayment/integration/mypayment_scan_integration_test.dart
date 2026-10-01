import 'dart:convert';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/last_time_scanned.dart';
import 'package:titan/mypayment/ui/pages/scan_page/scan_page.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The scan flow's QR payload: ScanInfo.fromJson consumes these keys
/// (tot is in cents, like every money field in the app; iat must be a
/// parseable ISO string — the decoder has no null fallback).
String scanPayload({required int tot}) => jsonEncode({
  'id': 'qr-1',
  'tot': tot,
  'iat': '2026-01-05T12:00:00.000Z',
  'key': 'k',
  'store': false,
  'signature': 'sig',
  'bypass_membership': false,
});

TransactionBase tx(String id, int total) =>
    TransactionBase.empty().copyWith(id: id, total: total);

/// The store the seller is currently manning. canBank reveals the Scan
/// button on the store card; the structure's membership decides whether
/// the scan modal renders the "Limited to" checkbox row. NOTE: the row
/// gate is `membership?.id != ''`, so an empty MembershipSimple — not a
/// null one — is what hides it (null still renders the row, blank label).
UserStore sellerStore({MembershipSimple? membership}) =>
    UserStore.empty().copyWith(
      id: 'store-1',
      name: 'BDE Store',
      structureId: 'structure-1',
      canBank: true,
      canSeeHistory: true,
      structure: Structure.empty().copyWith(
        id: 'structure-1',
        name: 'BDE',
        associationMembership: membership ?? MembershipSimple.empty(),
      ),
    );

void main() {
  late IntegrationScaffold scaffold;
  late FakeMobileScannerPlatform fakePlatform;
  MobileScannerPlatform? previousPlatform;

  /// Boots the app on the payment main page, flips the card to the store
  /// face and opens the scan modal. Every pump is raw: the scan page runs
  /// a permanently-repeating opacity animation, so pumpAndSettle would
  /// hang (convention 7).
  ///
  /// The viewport is 800x2000: the modal is 0.9x screen height and the
  /// scan zone reserves 0.8x screen width, so the stock 800x600 surface
  /// overflows the modal's column. A tall-but-narrow surface fits both.
  /// [width] narrows the surface further: the scan modal's membership row
  /// is sized from the FULL MediaQuery width while the bottom sheet is
  /// capped at 640px, so at desktop widths the close X overflows off-screen
  /// (known bug #24) — at phone widths the sheet is full-bleed and the X
  /// is tappable.
  /// Returns the container so tests can write scan-flow state directly.
  Future<ProviderContainer> openScanModal(
    WidgetTester tester, {
    double width = 800,
  }) async {
    tester.view.physicalSize = ui.Size(width, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = scaffold.makeContainer();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/mypayment',
      pumpAndSettle: false,
    );
    await settle(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowsRightLeft,
      ),
    );
    await settle(tester, frames: 16);
    expect(find.text('Store balance'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.viewfinderCircle,
      ),
    );
    await settle(tester, frames: 8);
    return container;
  }

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    previousPlatform = MobileScannerPlatform.instance;
    fakePlatform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fakePlatform;
    addTearDown(() {
      if (previousPlatform != null) {
        MobileScannerPlatform.instance = previousPlatform!;
      }
    });
  });

  /// Stubs the main page's loads plus the whole scan flow: the seller's
  /// stores (reveals the Scan button), the membership check, the scan POST
  /// and the transaction cancel. [scanAnswer] decides the scan POST reply.
  void stubScanFlow(
    IntegrationScaffold scaffold, {
    UserStore? store,
    bool membershipAllowed = true,
    Future<chopper.Response<TransactionBase>> Function(Invocation invocation)?
    scanAnswer,
  }) {
    when(
      () => scaffold.repository.mypaymentUsersMeWalletGet(),
    ).thenAnswer((_) async => chopperResponse(Wallet.empty()));
    when(
      () => scaffold.repository.mypaymentUsersMeStoresGet(),
    ).thenAnswer((_) async => chopperListResponse([store ?? sellerStore()]));
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopperResponse(
        TOSSignatureResponse.empty().copyWith(tosContent: ''),
      ),
    );
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
      () => scaffold.repository.mypaymentStoresStoreIdScanCheckPost(
        storeId: any(named: 'storeId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(
        AppTypesStandardResponsesResult(success: membershipAllowed),
      ),
    );
    when(
      () => scaffold.repository.mypaymentStoresStoreIdScanPost(
        storeId: any(named: 'storeId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      scanAnswer ?? ((_) async => chopperResponse(tx('tx-9', 2500))),
    );
    when(
      () => scaffold.repository.mypaymentTransactionsTransactionIdCancelPost(
        transactionId: any(named: 'transactionId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
  }

  group('mypayment scan modal', () {
    testWidgets(
      'a scan result opens the amount card and cancelling refunds through the dialog',
      (tester) async {
        final scannedBodies = <ScanInfo>[];
        stubScanFlow(
          scaffold,
          scanAnswer: (invocation) async {
            scannedBodies.add(invocation.namedArguments[#body] as ScanInfo);
            return chopperResponse(tx('tx-9', 2500));
          },
        );

        await openScanModal(tester);
        expect(find.byType(MobileScanner), findsOneWidget);
        expect(find.text('Scan a code'), findsOneWidget);

        // The camera surface receives a QR code; the app decodes it, checks
        // the membership and POSTs the scan.
        fakePlatform.emitScan(scanPayload(tot: 2500));
        await settle(tester, frames: 10);

        // The scanned value is echoed back as a QR image over the camera.
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Amount'), findsOneWidget);
        expect(find.textContaining('25,00'), findsOneWidget);

        // The raw payload reached the backend scan endpoint for this store.
        expect(scannedBodies.single.id, 'qr-1');
        expect(scannedBodies.single.tot, 2500);
        verify(
          () => scaffold.repository.mypaymentStoresStoreIdScanPost(
            storeId: 'store-1',
            body: any(named: 'body'),
          ),
        ).called(1);

        // While the 30s undo window runs, the cancel button opens a
        // confirmation dialog quoting the transaction amount.
        await tester.tap(find.textContaining('Cancel ('));
        await settle(tester, frames: 6);
        expect(
          find.textContaining('cancel the transaction of'),
          findsOneWidget,
        );

        await tester.tap(find.text('Confirm'));
        await settle(tester, frames: 10);
        await scaffold.drainToast(tester);

        // The refund round-trip happened and the modal reset for the next
        // customer: no amount card, no echoed QR, prompt back.
        verify(
          () =>
              scaffold.repository.mypaymentTransactionsTransactionIdCancelPost(
                transactionId: 'tx-9',
              ),
        ).called(1);
        expect(find.textContaining('25,00'), findsNothing);
        expect(find.byType(QrImageView), findsNothing);
        expect(find.text('Scan a code'), findsOneWidget);
      },
    );

    testWidgets('Next resets the scan surface for the next sale', (
      tester,
    ) async {
      final scannedBodies = <ScanInfo>[];
      stubScanFlow(
        scaffold,
        scanAnswer: (invocation) async {
          scannedBodies.add(invocation.namedArguments[#body] as ScanInfo);
          return chopperResponse(tx('tx-9', 2500));
        },
      );

      final container = await openScanModal(tester);
      fakePlatform.emitScan(scanPayload(tot: 2500));
      await settle(tester, frames: 10);
      expect(find.text('Amount'), findsOneWidget);

      // Next clears barcode + transaction and restarts the camera without
      // a backend cancel.
      await tester.tap(find.text('Next'));
      await settle(tester, frames: 10);
      expect(find.text('Amount'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Scan a code'), findsOneWidget);
      verifyNever(
        () => scaffold.repository.mypaymentTransactionsTransactionIdCancelPost(
          transactionId: any(named: 'transactionId'),
        ),
      );

      // The 5s anti-double-scan debounce gates the next scan; it compares
      // DateTime.now() (wall clock, unaffected by fake-async pumps), so the
      // test clears the timestamp to simulate the elapsed window.
      container.read(lastTimeScannedProvider.notifier).clearLastTimeScanned();
      fakePlatform.emitScan(scanPayload(tot: 1000));
      await settle(tester, frames: 10);

      expect(find.text('Amount'), findsOneWidget);
      expect(scannedBodies.length, 2);
      expect(scannedBodies.last.tot, 1000);
    });

    testWidgets(
      'non-member scans are gated by a confirmation dialog whose bypass reaches the backend',
      (tester) async {
        final scannedBodies = <ScanInfo>[];
        var checkCount = 0;
        stubScanFlow(
          scaffold,
          store: sellerStore(
            membership: MembershipSimple(
              name: 'BDE members',
              managerGroupId: '',
              id: 'm-1',
            ),
          ),
          membershipAllowed: false,
          scanAnswer: (invocation) async {
            scannedBodies.add(invocation.namedArguments[#body] as ScanInfo);
            return chopperResponse(tx('tx-9', 2500));
          },
        );
        when(
          () => scaffold.repository.mypaymentStoresStoreIdScanCheckPost(
            storeId: any(named: 'storeId'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((invocation) async {
          checkCount++;
          return chopperResponse(
            const AppTypesStandardResponsesResult(success: false),
          );
        });

        // 500px: wide enough for the main-page card rows, narrow enough
        // that the bottom sheet stays full-bleed so the close X is tappable
        // (bug #24, see openScanModal).
        await openScanModal(tester, width: 500);

        // The membership row renders with the checkbox checked (bypass off)
        // and the association name next to it.
        expect(find.byType(Checkbox), findsOneWidget);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
        expect(find.text('Limited to BDE members'), findsOneWidget);

        fakePlatform.emitScan(scanPayload(tot: 2500));
        await settle(tester, frames: 12);

        // The membership check ran first and refused the scan; a dialog
        // asks for explicit confirmation before bypassing.
        expect(checkCount, 1);
        expect(scannedBodies, isEmpty);
        expect(find.text('No membership'), findsOneWidget);
        expect(
          find.textContaining('not available to non-members'),
          findsOneWidget,
        );

        await tester.tap(find.text('Confirm'));
        await settle(tester, frames: 12);

        // The bypass flag travelled to the backend scan POST.
        expect(scannedBodies.single.bypassMembership, isTrue);
        expect(find.text('Amount'), findsOneWidget);
        expect(find.textContaining('25,00'), findsOneWidget);

        // Tapping the checkbox toggles the bypass for the NEXT scans.
        await tester.tap(find.byType(Checkbox));
        await settle(tester, frames: 4);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

        // The X next to the membership row closes the modal (scoped to the
        // modal: a same-icon X also exists under the modal in the shell).
        await tester.tap(
          find.descendant(
            of: find.byType(ScanPage),
            matching: find.byWidgetPredicate(
              (w) => w is HeroIcon && w.icon == HeroIcons.xMark,
            ),
          ),
        );
        await settle(tester, frames: 8);
        expect(find.byType(MobileScanner), findsNothing);
        expect(find.text('Limited to BDE members'), findsNothing);
      },
    );

    testWidgets('a backend scan error renders as an error card', (
      tester,
    ) async {
      stubScanFlow(
        scaffold,
        scanAnswer: (invocation) async =>
            throw AppException(ErrorType.notFound, 'QR expired'),
      );

      await openScanModal(tester);
      fakePlatform.emitScan(scanPayload(tot: 2500));
      await settle(tester, frames: 12);

      // The failed scan surfaces the backend message in the amount card.
      expect(find.text('QR expired'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      // The echoed QR stays on screen (the scan itself was received).
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('a store without membership hides the checkbox row', (
      tester,
    ) async {
      stubScanFlow(scaffold, store: sellerStore());

      // 500px for the tappable X (bug #24, see membership test).
      await openScanModal(tester, width: 500);

      expect(find.byType(Checkbox), findsNothing);
      expect(find.textContaining('Limited to'), findsNothing);

      // The X sits top-right and closes the modal (scoped to the modal;
      // see the membership test for why).
      await tester.tap(
        find.descendant(
          of: find.byType(ScanPage),
          matching: find.byWidgetPredicate(
            (w) => w is HeroIcon && w.icon == HeroIcons.xMark,
          ),
        ),
      );
      await settle(tester, frames: 8);
      expect(find.byType(MobileScanner), findsNothing);
    });
  });
}
