import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/selected_structure_provider.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/paiment_delegate_modal.dart';
import 'package:titan/mypayment/ui/pages/main_page/seller_card/structure_admin_card.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

/// The three main-page surfaces no other mypayment test drives:
///
/// 1. `StructureAdminCard.onTap` (structure_admin_card.dart:63-97) opens a
///    bottom modal whose two buttons select the structure and route — the
///    card itself renders on every admin boot, but nothing ever tapped it.
/// 2. The card face's second tap (`toggle()`'s `flipped.value == true` arm,
///    main_page.dart:87-89) — the flip tests only ever flip forward once.
/// 3. The pending payment-request sheet scheduled from the page's request
///    `useEffect` (main_page.dart:112-136) and its accept `onSuccess`
///    callback (main_page.dart:100-102), which the widget-level modal tests
///    never reach because they call `showRequestModal` directly.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final bdeStructure = structureFixture('structure-1', 'BDE', 'user-1');

  /// Every read the payment main page performs on boot, plus the bank
  /// account holder: returning `bdeStructure` flips
  /// `isBankAccountHolderProvider` to true so `StoreList` also renders its
  /// `InvoiceAdminCard` branch (store_list.dart:58).
  void stubMainPage(IntegrationScaffold scaffold, {List<Request$>? requests}) {
    when(() => scaffold.repository.mypaymentUsersMeWalletGet()).thenAnswer(
      (_) async => chopperResponse(
        Wallet.empty().copyWith(id: 'wallet-1', balance: 2510),
      ),
    );
    when(() => scaffold.repository.mypaymentUsersMeStoresGet())
        .thenAnswer((_) async => chopperListResponse(<UserStore>[]));
    when(() => scaffold.repository.mypaymentUsersMeTosGet()).thenAnswer(
      (_) async => chopperResponse(
        TOSSignatureResponse.empty().copyWith(
          acceptedTosVersion: 0,
          latestTosVersion: 0,
          tosContent: 'Some terms',
        ),
      ),
    );
    when(() => scaffold.repository.mypaymentRequestsGet())
        .thenAnswer((_) async => chopperListResponse(requests ?? <Request$>[]));
    when(() => scaffold.repository.mypaymentStructuresGet())
        .thenAnswer((_) async => chopperListResponse([bdeStructure]));
    when(() => scaffold.repository.mypaymentUsersMeWalletHistoryGet())
        .thenAnswer((_) async => chopperListResponse(<History>[]));
    when(() => scaffold.repository.mypaymentBankAccountHolderGet())
        .thenAnswer((_) async => chopperResponse(bdeStructure));
  }

  /// Flips the account card to the store card (and back): both faces share
  /// the SAME `toggle` closure, so each tap lands on whichever face is on
  /// top and still advances `flipped`.
  Future<void> flipCard(WidgetTester tester) async {
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowsRightLeft,
      ),
      warnIfMissed: false,
    );
    await settle(tester, frames: 16);
  }

  Finder modalButtons() => find.descendant(
    of: find.byType(BottomModalTemplate),
    matching: find.byType(Button),
  );

  testWidgets(
    "the admin card's Stores button routes to the structure's stores",
    (tester) async {
      // NAVIGATION TEST FIRST: qlevar_router 1.12.4 silently drops the first
      // mid-test QR.to() to a not-yet-mounted route once an earlier test has
      // run in the same isolate, so this is the file's only path assertion.
      stubMainPage(scaffold);

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        // Pre-seeded so the AdminMiddleware gate on /structureStores resolves
        // synchronously instead of bouncing while the repository read is in
        // flight.
        myStructures: [bdeStructure],
      );
      addTearDown(container.dispose);
      await scaffold.pumpApp(tester, container, initialPath: '/mypayment');
      await settle(tester);

      // Forward to the store face, then back (the reverse arm of toggle():
      // controller.reverse() + the two provider invalidations), then forward
      // again so StoreList — and the admin card inside it — is visible.
      await flipCard(tester);
      expect(find.text('Store balance'), findsOneWidget);
      await flipCard(tester);
      expect(find.text('Personal balance'), findsOneWidget);
      await flipCard(tester);

      expect(find.byType(StructureAdminCard), findsOneWidget);
      await tester.tap(find.byType(StructureAdminCard));
      await settle(tester, frames: 10);

      expect(find.byType(BottomModalTemplate), findsOneWidget);
      expect(modalButtons(), findsNWidgets(2));

      await tester.tap(modalButtons().at(0)); // "Stores"
      await settle(tester, frames: 16);

      // The button popped the modal, selected the structure and routed; the
      // page renders its header from the selected structure's name.
      expect(QR.currentPath, '/mypayment/structureStores');
      expect(find.textContaining('BDE management'), findsOneWidget);
    },
  );

  testWidgets(
    "the admin card's Invoices button selects the structure and loads its invoices",
    (tester) async {
      stubMainPage(scaffold);
      when(
        () => scaffold.repository.mypaymentInvoicesStructuresStructureIdGet(
          structureId: 'structure-1',
          page: 1,
          pageSize: 20,
          startDate: null,
          endDate: null,
        ),
      ).thenAnswer(
        (_) async =>
            chopperListResponse([Invoice.empty().copyWith(id: 'inv-1')]),
      );

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        myStructures: [bdeStructure],
        // Deliberately NOT seeded: the assertion is that the button's
        // setStructure() put 'structure-1' here.
      );
      addTearDown(container.dispose);
      await scaffold.pumpApp(tester, container, initialPath: '/mypayment');
      await settle(tester);

      await flipCard(tester);
      expect(find.byType(StructureAdminCard), findsOneWidget);
      await tester.tap(find.byType(StructureAdminCard));
      await settle(tester, frames: 10);

      await tester.tap(modalButtons().at(1)); // "Invoices"
      await settle(tester, frames: 16);

      // No path assertion: this is the file's SECOND mid-test QR.to() and
      // qlevar may drop it (ordering quirk noted above). The button's own
      // effects — select the structure, fetch its invoices — are what the
      // lines under test do regardless.
      expect(container.read(selectedStructureProvider).id, 'structure-1');
      verify(
        () => scaffold.repository.mypaymentInvoicesStructuresStructureIdGet(
          structureId: 'structure-1',
          page: 1,
          pageSize: 20,
          startDate: null,
          endDate: null,
        ),
      ).called(1);
    },
  );

  testWidgets(
    'a pending payment request opens its sheet and accepting it refreshes the page',
    (tester) async {
      Request$ request({
        required String id,
        required RequestStatus status,
        required DateTime expirationDate,
      }) => Request$(
        id: id,
        walletId: 'wallet-1',
        creation: DateTime.now().subtract(const Duration(hours: 1)),
        expirationDate: expirationDate,
        total: 1250,
        storeId: 'store-1',
        name: 'Cafe des Arts',
        module: 'mypayment',
        objectId: 'object-1',
        status: status,
      );

      // Three shapes so BOTH closures in main_page's request effect run for
      // real: the removeWhere predicate (expired + already-decided requests)
      // and the nextPending filter (the live one that must survive).
      stubMainPage(
        scaffold,
        requests: [
          request(
            id: 'req-live-main-admin',
            status: RequestStatus.proposed,
            expirationDate: DateTime.now().add(const Duration(minutes: 5)),
          ),
          request(
            id: 'req-expired-main-admin',
            status: RequestStatus.proposed,
            expirationDate: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          request(
            id: 'req-decided-main-admin',
            status: RequestStatus.accepted,
            expirationDate: DateTime.now().add(const Duration(minutes: 5)),
          ),
        ],
      );
      when(
        () => scaffold.repository.mypaymentRequestsRequestIdAcceptPost(
          requestId: any(named: 'requestId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => chopperResponseVoid());

      // The delegate sheet is sized for real text metrics: under the harness
      // square-font it overflows the default 600px surface by 40px, which
      // pushes the confirm button out of the hit area (pumpApp has no
      // appFonts option, so a taller surface is the harness-side fix).
      tester.view.physicalSize = const ui.Size(800, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        // The accept path signs the envelope with the device key; without a
        // registered key it takes the error branch and never reaches onSuccess.
        deviceKeyId: 'device-1',
      );
      addTearDown(container.dispose);

      // BOUNDED pumps on purpose: the delegate sheet starts a repeating
      // shimmer and a 299s countdown as soon as it mounts, so a
      // pumpAndSettle would advance the fake clock ~300 virtual seconds
      // before returning — expiry flips both isExpired flags and the confirm
      // tap below would be silently ignored.
      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/mypayment',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 20);

      // The effect scheduled the modal post-frame once the request list had
      // data; only the live request survived both filters.
      expect(find.byType(PaimentDelegateModal), findsOneWidget);
      expect(find.text('Cafe des Arts'), findsOneWidget);

      final confirm = find.text('Confirm Payment');
      expect(confirm, findsOneWidget);
      await tester.tap(confirm);
      await settle(tester, frames: 20);

      expect(find.byType(PaimentDelegateModal), findsNothing);
      verify(
        () => scaffold.repository.mypaymentRequestsRequestIdAcceptPost(
          requestId: 'req-live-main-admin',
          body: any(named: 'body'),
        ),
      ).called(1);
      // The accept success callback (main_page.dart:100-102) re-reads both
      // lists on top of their boot reads.
      verify(() => scaffold.repository.mypaymentUsersMeWalletHistoryGet())
          .called(2);
      verify(() => scaffold.repository.mypaymentUsersMeWalletGet()).called(2);

      // The success toast arms an auto-close timer (convention 21).
      await scaffold.unmountApp(tester);
      await scaffold.drainToast(tester);
    },
  );
}
