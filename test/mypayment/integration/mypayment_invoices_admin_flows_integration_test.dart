import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The invoices-admin page's action block, which the page-shell test never
/// reaches: the pagination row (page back/forward + the page-size dropdown)
/// and the create-invoice bottom modal (empty-structure guard, chip
/// selection, success round-trip, refusal toast).
///
/// The page itself loads nothing on mount — `invoiceListProvider` is
/// pre-seeded through `makeContainer(invoices:)` — so every GET here counts
/// exactly the refreshes the actions trigger.
final bde = structureFixture('s-1', 'BDE', 'user-1');

Invoice invoice(int n) => Invoice.empty().copyWith(
  id: 'inv-$n',
  reference: 'FA-2026-${n.toString().padLeft(3, '0')}',
  total: 1250 + n,
  structure: bde,
);

void stubInvoices(IntegrationScaffold scaffold) {
  // InvoiceCard previews the invoice PDF on build.
  when(
    () => scaffold.repository.mypaymentInvoicesInvoiceIdGet(
      invoiceId: any(named: 'invoiceId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopper.Response(http.Response.bytes([1, 2, 3], 200), [1, 2, 3]),
  );
  // The pre-seeded notifier answers refreshes itself only for the initial
  // state; pagination/create call the real endpoint.
  when(
    () => scaffold.repository.mypaymentInvoicesGet(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
      structuresIds: any(named: 'structuresIds'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => chopperListResponse(<Invoice>[]));
  when(() => scaffold.repository.mypaymentUsersMeStoresGet())
      .thenAnswer((_) async => chopperListResponse(<UserStore>[]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpInvoices(
    WidgetTester tester, {
    List<Invoice> invoices = const [],
  }) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        // isBankAccountHolderProvider requires the holder structure to be
        // among the structures the user manages; pre-seeded so the async
        // gate resolves before the redirect is evaluated.
        myStructures: [bde],
        bankAccountHolder: bde,
        invoices: invoices,
      ),
      initialPath: '/mypayment/invoicesAdmin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);
  }

  testWidgets('the pagination row pages back/forth and re-sizes the list', (
    tester,
  ) async {
    stubInvoices(scaffold);
    await pumpInvoices(tester, invoices: List.generate(20, invoice));

    // Mounted at page 1, 20 per page: the forward arrow is enabled
    // (20 >= 20) and no request has fired yet — the list came pre-seeded.
    verifyNever(
      () => scaffold.repository.mypaymentInvoicesGet(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        structuresIds: any(named: 'structuresIds'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    );

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowRight,
      ),
    );
    await settle(tester, frames: 20);
    verify(
      () => scaffold.repository.mypaymentInvoicesGet(
        page: 2,
        pageSize: 20,
        structuresIds: null,
        startDate: null,
        endDate: null,
      ),
    ).called(1);

    // Back to page 1: the left arrow's enabled branch (page.value > 1).
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.arrowLeft,
      ),
    );
    await settle(tester, frames: 20);
    verify(
      () => scaffold.repository.mypaymentInvoicesGet(
        page: 1,
        pageSize: 20,
        structuresIds: null,
        startDate: null,
        endDate: null,
      ),
    ).called(1);

    // The page-size dropdown re-queries with the new size.
    await tester.tap(find.byType(DropdownButton<int>));
    await settle(tester, frames: 10);
    await tester.tap(find.text('10 invoices/page'));
    await settle(tester, frames: 20);
    verify(
      () => scaffold.repository.mypaymentInvoicesGet(
        page: 1,
        pageSize: 10,
        structuresIds: null,
        startDate: null,
        endDate: null,
      ),
    ).called(1);
  });

  testWidgets('creating an invoice guards the empty selection, then lands', (
    tester,
  ) async {
    stubInvoices(scaffold);
    when(
      () => scaffold.repository.mypaymentInvoicesStructuresStructureIdPost(
        structureId: any(named: 'structureId'),
      ),
    ).thenAnswer((_) async => chopperResponse(invoice(99)));

    await pumpInvoices(tester);

    await scaffold.openModal(tester, find.text('Create new invoice'));
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('Select a structure'), findsOneWidget);
    // The modal title duplicates the row behind it while open.
    expect(find.text('Create new invoice'), findsNWidgets(2));
    expect(find.text('BDE'), findsOneWidget);

    // Guard first: nothing selected (structureProvider starts at
    // Structure.empty) → Create is a silent no-op and the modal stays up.
    await scaffold.tapInModal(tester, find.text('Create'));
    verifyNever(
      () => scaffold.repository.mypaymentInvoicesStructuresStructureIdPost(
        structureId: any(named: 'structureId'),
      ),
    );
    expect(scaffold.isModalOpen(tester), isTrue);

    await scaffold.tapInModal(tester, find.text('BDE'));
    await scaffold.tapInModal(tester, find.text('Create'));
    await settle(tester, frames: 30);

    verify(
      () => scaffold.repository.mypaymentInvoicesStructuresStructureIdPost(
        structureId: 's-1',
      ),
    ).called(1);
    expect(scaffold.isModalOpen(tester), isFalse);
    // The success arm refreshes the list — the one GET of this test.
    verify(
      () => scaffold.repository.mypaymentInvoicesGet(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        structuresIds: any(named: 'structuresIds'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).called(1);
    expect(find.text('Invoice created successfully'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused invoice creation toasts the no-invoice error', (
    tester,
  ) async {
    stubInvoices(scaffold);
    when(
      () => scaffold.repository.mypaymentInvoicesStructuresStructureIdPost(
        structureId: any(named: 'structureId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.fail(400));

    await pumpInvoices(tester);

    await scaffold.openModal(tester, find.text('Create new invoice'));
    await scaffold.tapInModal(tester, find.text('BDE'));
    await scaffold.tapInModal(tester, find.text('Create'));
    await settle(tester, frames: 30);

    // add() reads the non-2xx as a failure: the error arm toasts (the
    // modal popped before the await, by design).
    expect(find.text('No invoice to create'), findsOneWidget);
    expect(scaffold.isModalOpen(tester), isFalse);
    await scaffold.drainToast(tester);
  });
}
