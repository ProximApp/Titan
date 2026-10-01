import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/exception.dart';

import '../../shared/app_scaffold.dart';

SellerComplete seller() =>
    SellerComplete.empty().copyWith(id: 'seller-1', name: 'BDE Bar');

GenerateTicketComplete generator() => GenerateTicketComplete.empty().copyWith(
  id: 'gen-1',
  name: 'Soirée des clubs',
  maxUse: 10,
  expiration: DateTime(2100),
);

AppModulesCdrSchemasCdrProductVariantComplete variant() =>
    AppModulesCdrSchemasCdrProductVariantComplete.empty().copyWith(
      id: 'var-1',
      productId: 'prod-1',
      nameFr: 'Demo',
      price: 100,
    );

AppModulesCdrSchemasCdrProductComplete product() =>
    AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
      id: 'prod-1',
      nameFr: 'Consumption',
      sellerId: 'seller-1',
      variants: [variant()],
      tickets: [generator()],
    );

/// The backend answer to the scan GET: the seller-side view of the buyer's
/// ticket after the membership check.
AppModulesCdrSchemasCdrTicket scannedTicket() =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: 't-1',
      name: 'Soirée des clubs',
      scanLeft: 9,
      expiration: DateTime(2100),
      user: UserTicket.empty().copyWith(
        id: 'u-1',
        firstname: 'Maxime',
        name: 'Roucher',
      ),
      productVariant: variant(),
    );

void main() {
  late IntegrationScaffold scaffold;
  late FakeMobileScannerPlatform fakePlatform;
  MobileScannerPlatform? previousPlatform;

  /// Stubs the scan page's loads plus the whole scan round-trip. The
  /// scanned secrets handed to the GET and PATCH are recorded so tests can
  /// assert which secret the backend actually received.
  final getSecrets = <String?>[];
  final patchSecrets = <String?>[];

  void stubScanFlow(IntegrationScaffold scaffold, {Object? getAnswer}) {
    // The dialog's Valider goes through TicketListNotifier.update, whose
    // state must already hold the buyer ticket (build() loads it).
    when(() => scaffold.repository.cdrUsersMeTicketsGet()).thenAnswer(
      (_) async =>
          chopperListResponse<AppModulesCdrSchemasCdrTicket>([scannedTicket()]),
    );
    when(
      () => scaffold.repository.cdrSellersSellerIdProductsGet(
        sellerId: any(named: 'sellerId'),
      ),
    ).thenAnswer(
      (_) async => chopperListResponse<AppModulesCdrSchemasCdrProductComplete>([
        product(),
      ]),
    );
    when(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
            secret: any(named: 'secret'),
          ),
    ).thenAnswer((invocation) async {
      getSecrets.add(invocation.namedArguments[#secret] as String?);
      if (getAnswer is AppException) throw getAnswer;
      return chopperResponse(scannedTicket());
    });
    when(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
            secret: any(named: 'secret'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((invocation) async {
      patchSecrets.add(invocation.namedArguments[#secret] as String?);
      return chopperResponseVoid();
    });
  }

  /// The dialog's content overflows its box, so the Valider/Annuler row
  /// sits below the fold of the dialog's SingleChildScrollView; scroll it
  /// into view before tapping (convention 8).
  Future<void> revealInDialog(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester, frames: 2);
  }

  /// Boots the scan page deep-linked at /purchases/scan (admin-gated; the
  /// seller list pre-seed settles the gate deterministically), selects the
  /// seller chip and opens the ScanDialog for the product's ticket.
  Future<void> openScanDialog(WidgetTester tester) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(purchasesSellers: [seller()]),
      initialPath: '/purchases/scan',
    );
    expect(find.text('Please select a seller'), findsOneWidget);

    await tester.tap(find.text('BDE Bar'));
    await settle(tester, frames: 6);
    // The ticket card shows the ticket's name (the product name is not
    // rendered on the card).
    expect(find.text('Soirée des clubs'), findsOneWidget);

    await tester.tap(find.textContaining('10 scans maximun'));
    await settle(tester, frames: 10);
    expect(find.text('Ajouter un tag pour les scans'), findsOneWidget);
  }

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    previousPlatform = MobileScannerPlatform.instance;
    fakePlatform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fakePlatform;
    getSecrets.clear();
    patchSecrets.clear();
    addTearDown(() {
      if (previousPlatform != null) {
        MobileScannerPlatform.instance = previousPlatform!;
      }
    });
  });

  group('Purchases scan page', () {
    testWidgets('a seller chip reveals the product tickets', (tester) async {
      stubScanFlow(scaffold);

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(purchasesSellers: [seller()]),
        initialPath: '/purchases/scan',
      );
      expect(find.text('Please select a seller'), findsOneWidget);

      await tester.tap(find.text('BDE Bar'));
      await settle(tester, frames: 6);

      // The product's ticket card carries the scan budget and expiry.
      expect(find.text('Soirée des clubs'), findsOneWidget);
      expect(find.textContaining('10 scans maximun'), findsOneWidget);
      verify(
        () => scaffold.repository.cdrSellersSellerIdProductsGet(
          sellerId: 'seller-1',
        ),
      ).called(1);
    });

    testWidgets('the scan dialog walks tag → scan → ticket confirmation', (
      tester,
    ) async {
      stubScanFlow(scaffold);

      await openScanDialog(tester);

      // The tag typed here must reach the confirm PATCH body later.
      await tester.enterText(find.byType(TextField), 'Entrée 42');
      await tester.tap(find.text('Scanner'));
      await settle(tester, frames: 10);

      // The scanner phase replaced the tag form; the typed tag is echoed.
      expect(find.byType(MobileScanner), findsOneWidget);
      expect(find.text('Tag : Entrée 42'), findsOneWidget);

      fakePlatform.emitScan('secret-abc');
      await settle(tester, frames: 12);

      // The scan GET ran; the dialog shows the buyer's ticket.
      verify(
        () => scaffold.repository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet(
              sellerId: 'seller-1',
              productId: 'prod-1',
              generatorId: 'gen-1',
              secret: any(named: 'secret'),
            ),
      ).called(1);
      expect(find.text('Maxime Roucher'), findsOneWidget);
      expect(find.text('Variant : Demo'), findsOneWidget);
      expect(find.text('9 / 10 Scans remaining'), findsOneWidget);

      // Valider consumes the ticket with the typed tag.
      await revealInDialog(tester, find.text('Valider'));
      await tester.tap(find.text('Valider'));
      await settle(tester, frames: 12);
      await scaffold.drainToast(tester);

      verify(
        () => scaffold.repository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch(
              sellerId: 'seller-1',
              productId: 'prod-1',
              generatorId: 'gen-1',
              secret: any(named: 'secret'),
              body: any(named: 'body'),
            ),
      ).called(1);
      // Success resets the dialog to the waiting scanner.
      expect(find.text('Waiting for scan'), findsOneWidget);
    });

    testWidgets('the scanned secret never reaches the backend (stale '
        'scanner closure, ledger #25)', (tester) async {
      stubScanFlow(scaffold);

      await openScanDialog(tester);
      await tester.tap(find.text('Scanner'));
      await settle(tester, frames: 10);
      fakePlatform.emitScan('secret-abc');
      await settle(tester, frames: 12);
      await revealInDialog(tester, find.text('Valider'));
      await tester.tap(find.text('Valider'));
      await settle(tester, frames: 12);
      await scaffold.drainToast(tester);

      // Both endpoints received the empty default: onScan captures
      // `scanner` at build time, and setSecret only runs in the data
      // branch of the OLD (loading) snapshot — so the notifier's secret
      // stays "" for the confirm PATCH too. Fix: resolve the current state
      // via ref.read inside onScan (or pass the secret to the notifier).
      expect(getSecrets.single, '');
      expect(patchSecrets.single, '');
    });

    testWidgets('a rejected scan surfaces the backend error and resets', (
      tester,
    ) async {
      stubScanFlow(
        scaffold,
        getAnswer: AppException(ErrorType.notFound, 'Unknown ticket'),
      );

      await openScanDialog(tester);
      await tester.tap(find.text('Scanner'));
      await settle(tester, frames: 10);
      fakePlatform.emitScan('secret-abc');
      await settle(tester, frames: 12);
      await scaffold.drainToast(tester);

      // The dialog renders the error branch with the backend message.
      expect(find.text('Erreur'), findsOneWidget);
      expect(find.textContaining('notFound : Unknown ticket'), findsOneWidget);
      verifyNever(
        () => scaffold.repository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch(
              sellerId: any(named: 'sellerId'),
              productId: any(named: 'productId'),
              generatorId: any(named: 'generatorId'),
              secret: any(named: 'secret'),
              body: any(named: 'body'),
            ),
      );

      // The 2s auto-reset NEVER fires: the error branch that schedules it
      // lives in onScan's `scanner.when`, which reads the STALE build-time
      // snapshot (still loading) — so the scheduled reset is dead code and
      // the dialog stays stuck on the error (bug #25's blast radius; a
      // ref.read-based fix heals the toast + reset too).
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Waiting for scan'), findsNothing);
      expect(find.text('Erreur'), findsOneWidget);
    });

    testWidgets('Annuler resets the dialog without consuming', (tester) async {
      stubScanFlow(scaffold);

      await openScanDialog(tester);
      await tester.tap(find.text('Scanner'));
      await settle(tester, frames: 10);
      fakePlatform.emitScan('secret-abc');
      await settle(tester, frames: 12);
      expect(find.text('Maxime Roucher'), findsOneWidget);

      await revealInDialog(tester, find.text('Annuler'));
      await tester.tap(find.text('Annuler'));
      await settle(tester, frames: 10);

      expect(find.text('Waiting for scan'), findsOneWidget);
      expect(find.text('Maxime Roucher'), findsNothing);
      verifyNever(
        () => scaffold.repository
            .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch(
              sellerId: any(named: 'sellerId'),
              productId: any(named: 'productId'),
              generatorId: any(named: 'generatorId'),
              secret: any(named: 'secret'),
              body: any(named: 'body'),
            ),
      );
    });
  });
}
