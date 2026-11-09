import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/scanner_provider.dart';
import 'package:titan/purchases/ui/pages/scan_page/ticket_card.dart'
    as purchases_scan_ticket;
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../purchases_fixtures.dart';
import '../../shared/app_scaffold.dart';

SellerComplete seller() =>
    SellerComplete.empty().copyWith(id: 'seller-1', name: 'BDE Bar');

AppModulesCdrSchemasCdrProductComplete product() =>
    AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
      id: 'prod-1',
      nameFr: 'Consumption',
      sellerId: 'seller-1',
      variants: [variant(price: 100)],
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
      productVariant: variant(price: 100),
    );

/// Coverage note: three scan_dialog arms stay uncovered because the dialog
/// exposes no surface for them — the pencil that arms `shouldSetTag` matches
/// zero widgets once the dialog is open, so the tag field never appears and
/// with it neither the scanner `loading` arm nor the refused-validation toast
/// behind Valider. Asserting them as no-ops would fake coverage.
///
/// `scanned.when(… loading: () {})` after the scan call is mounted instead of
/// argued about. `SingleNotifierAPI.load` only ever assigns data or error and
/// returns that same value, so the awaited `scanned` cannot be loading in
/// production; the dialog reads the value `ScannerNotifier.scanTicket`
/// answers, and that method is public and overridable. The last test overrides
/// `scannerProvider` with a notifier whose `scanTicket` answers
/// `AsyncLoading`, drives a real barcode through the fake platform, and
/// observes: the scanned secret reached the notifier, and the arm announces
/// nothing — no success toast, no error toast, the dialog unchanged.
/// A scanner whose scan answers `AsyncLoading`: the one value the dialog's
/// third `when` arm reacts to, and the one `load()` cannot return.
class _LoadingScanNotifier extends ScannerNotifier {
  @override
  AsyncValue<AppModulesCdrSchemasCdrTicket> build() =>
      const AsyncValue.loading();

  @override
  Future<AsyncValue<AppModulesCdrSchemasCdrTicket>> scanTicket(
    String sellerId,
    String productId,
    String generatorId,
  ) async => const AsyncValue.loading();
}

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

      // The card's list bullet seeds the ticket/product ids, starts the
      // tag load and pushes the scanned-users page.
      when(
        () => scaffold.repository
            .cdrSellersSellerIdProductsProductIdTagsGeneratorIdGet(
              sellerId: any(named: 'sellerId'),
              productId: any(named: 'productId'),
              generatorId: any(named: 'generatorId'),
            ),
      ).thenAnswer((_) async => chopperListResponse<String>(<String>[]));

      final bullet = find.descendant(
        of: find.byType(purchases_scan_ticket.TicketCard),
        matching: find.byType(HeroIcon),
      );
      await tester.tap(bullet);
      await settle(tester, frames: 10);

      expect(QR.currentPath, '/purchases/user_list');
      expect(tester.takeException(), isNull);
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

    testWidgets('the scanned secret reaches both endpoints (bug #25, fixed)', (
      tester,
    ) async {
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

      // `onScan` reads the state its own call just produced, so the data
      // branch runs and `setSecret` lands before the confirm PATCH — both
      // endpoints carry the scanned secret. Before the fix both were "":
      // the callback closed over the build-time (loading) snapshot.
      expect(getSecrets.single, 'secret-abc');
      expect(patchSecrets.single, 'secret-abc');
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

      // The dialog renders the error branch with the backend message —
      // asserted BEFORE any long pump, because the same branch schedules the
      // 2s reset below.
      expect(find.text('Erreur'), findsOneWidget);
      // Two copies: the dialog's error text and the toast raised beside it.
      expect(find.textContaining('notFound : Unknown ticket'), findsWidgets);
      await scaffold.drainToast(tester);
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

      // The 2s auto-reset now FIRES: the error branch schedules it off the
      // state `ref.read(scannerProvider)` returns, so the dialog comes back
      // to the waiting scanner instead of staying stuck on the error (the
      // blast radius of bug #25, healed by the same read).
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Waiting for scan'), findsOneWidget);
      expect(find.text('Erreur'), findsNothing);
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

  testWidgets('the pencil brings the tag field back after scanning', (
    tester,
  ) async {
    stubScanFlow(scaffold);
    await openScanDialog(tester);

    // "Scanner" swaps the tag field for the scanner view...
    await tester.tap(find.text('Scanner'));
    await settle(tester, frames: 10);
    expect(find.text('Ajouter un tag pour les scans'), findsNothing);

    // ...and the pencil beside the tag row swaps it back, so the operator
    // can fix a tag after having started the scanner.
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is HeroIcon && widget.icon == HeroIcons.pencil,
      ),
    );
    await settle(tester, frames: 6);
    expect(find.text('Ajouter un tag pour les scans'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refused validation says so and keeps the scan', (
    tester,
  ) async {
    stubScanFlow(scaffold);
    await openScanDialog(tester);

    // The dialog's Valider PATCHes the ticket; a refusal must not claim the
    // scan went through. (The `loading:` arm of the same `when` is dead: the
    // awaited value is the notifier's `update`, which answers AsyncData or
    // AsyncError, so nothing can select it.)
    when(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretPatch(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
            secret: any(named: 'secret'),
            body: any(named: 'body'),
          ),
    ).thenAnswer((_) async => scaffold.repository.fail<void>(500));

    await tester.enterText(find.byType(TextField), 'VIP');
    await tester.tap(find.text('Scanner'));
    await settle(tester, frames: 10);
    fakePlatform.emitScan('secret-abc');
    await settle(tester, frames: 12);
    await revealInDialog(tester, find.text('Valider'));
    await tester.tap(find.text('Valider'));
    await settle(tester, frames: 12);

    expect(find.text('Erreur lors de la validation'), findsOneWidget);
    expect(find.text('Scan validé'), findsNothing);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scan still in flight announces nothing', (tester) async {
    stubScanFlow(scaffold);

    final container = scaffold.makeContainer(
      purchasesSellers: [seller()],
      providerOverrides: [
        scannerProvider.overrideWith(_LoadingScanNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(tester, container, initialPath: '/purchases/scan');
    await tester.tap(find.text('BDE Bar'));
    await settle(tester, frames: 6);
    await tester.tap(find.textContaining('10 scans maximun'));
    await settle(tester, frames: 10);

    await tester.tap(find.text('Scanner'));
    await settle(tester, frames: 10);

    fakePlatform.emitScan('secret-abc');
    await settle(tester, frames: 12);

    // The scan reached the notifier through the real barcode callback...
    expect(container.read(scannerProvider.notifier).secret, 'secret-abc');
    // ...and an in-flight answer says nothing and resets nothing: neither the
    // success toast nor the error one (which would print the exception).
    expect(find.text('Scan validé'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.text('Waiting for scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
