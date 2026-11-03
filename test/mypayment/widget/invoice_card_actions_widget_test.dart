import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/ui/components/invoice_card.dart';

import '../../shared/app_scaffold.dart';

/// [InvoiceCard]'s action sheet — the three things an invoice can actually do,
/// none of which any invoice test reached: an admin marks it paid/unpaid, an
/// admin deletes it, and the payer marks it received.
///
/// The card is where money status changes, and each branch is the same
/// three-part shape (`update`/`delete` → success toast → refresher, or an
/// error toast). The failure arms are the ones that matter: a status flip that
/// silently fails must SAY so, because the invoice list it refreshes would
/// otherwise look like the change was rejected for the wrong reason.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Invoice invoice({
    bool? paid,
    bool? received,
    String reference = 'FAC-2026-001',
  }) => Invoice.empty().copyWith(
    id: 'inv-1',
    reference: reference,
    total: 2500,
    paid: paid,
    received: received,
    structure: Structure.empty().copyWith(id: 'struct-1', name: 'BDE'),
  );

  /// The card always watches the PDF (its download button) and the write
  /// endpoints are what the three actions call.
  void stubInvoice(IntegrationScaffold scaffold) {
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdGet(
        invoiceId: any(named: 'invoiceId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response.bytes([1, 2, 3], 200),
        [1, 2, 3],
      ),
    );
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdPaidPatch(
        invoiceId: any(named: 'invoiceId'),
        paid: any(named: 'paid'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdReceivedPatch(
        invoiceId: any(named: 'invoiceId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdDelete(
        invoiceId: any(named: 'invoiceId'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
  }

  /// Mounts the card and returns the refresher's hit counter — the callback
  /// the page passes so the list re-reads after a successful write.
  Future<List<int>> mount(
    WidgetTester tester,
    Invoice theInvoice, {
    bool isAdmin = true,
  }) async {
    final refreshes = <int>[];
    final container = scaffold.makeContainer(invoices: [theInvoice]);
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: InvoiceCard(
            invoice: theInvoice,
            isAdmin: isAdmin,
            invoicesRefresher: () => refreshes.add(1),
          ),
        ),
      ),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );
    return refreshes;
  }

  testWidgets('an admin marking an invoice paid writes it and refreshes', (
    tester,
  ) async {
    stubInvoice(scaffold);
    final refreshes = await mount(tester, invoice());

    // The status line starts unpaid, and the sheet offers the flip.
    expect(find.text('Pending'), findsOneWidget);
    await scaffold.openModal(tester, find.text('FAC-2026-001'));
    expect(find.text('Mark as paid'), findsOneWidget);

    await scaffold.tapInModal(tester, find.text('Mark as paid'));
    await settle(tester, frames: 6);

    verify(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdPaidPatch(
        invoiceId: 'inv-1',
        paid: true,
      ),
    ).called(1);
    expect(find.text('Successfully modified'), findsOneWidget);
    expect(
      refreshes,
      hasLength(1),
      reason: 'a successful write must re-read the list it just changed',
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('a paid invoice offers the unpaid flip', (tester) async {
    stubInvoice(scaffold);
    await mount(tester, invoice(paid: true));

    expect(find.text('Paid'), findsOneWidget);
    await scaffold.openModal(tester, find.text('FAC-2026-001'));
    expect(find.text('Mark as unpaid'), findsOneWidget);

    await scaffold.tapInModal(tester, find.text('Mark as unpaid'));
    await settle(tester, frames: 6);

    verify(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdPaidPatch(
        invoiceId: 'inv-1',
        paid: false,
      ),
    ).called(1);
    await scaffold.drainToast(tester);
  });

  testWidgets('a failed status flip reports the error instead of refreshing', (
    tester,
  ) async {
    stubInvoice(scaffold);
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdPaidPatch(
        invoiceId: any(named: 'invoiceId'),
        paid: any(named: 'paid'),
      ),
    ).thenThrow(Exception('backend down'));
    final refreshes = await mount(tester, invoice());

    await scaffold.openModal(tester, find.text('FAC-2026-001'));
    await scaffold.tapInModal(tester, find.text('Mark as paid'));
    await settle(tester, frames: 6);

    // The user is told the write failed, and the list is NOT refreshed as if
    // it had succeeded. The diagnostic prints every rendered string so a
    // wording change names the real toast instead of a bare 'not found'.
    expect(
      anyVisibleTextContains(tester, 'error'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    expect(refreshes, isEmpty);
    await scaffold.drainToast(tester);
  });

  testWidgets('an admin deleting an unpaid invoice confirms first', (
    tester,
  ) async {
    stubInvoice(scaffold);
    await mount(tester, invoice());

    await scaffold.openModal(tester, find.text('FAC-2026-001'));
    await scaffold.tapInModal(tester, find.text('Delete invoice'));

    // The delete is behind a confirmation, and nothing is sent before it.
    expect(find.text('This action is irreversible'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdDelete(
        invoiceId: any(named: 'invoiceId'),
      ),
    );

    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);

    verify(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdDelete(
        invoiceId: 'inv-1',
      ),
    ).called(1);
    expect(
      anyVisibleTextContains(tester, 'Successfully deleted'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('the payer marks a paid invoice received', (tester) async {
    stubInvoice(scaffold);
    // Not an admin: this is the person the invoice was issued to.
    await mount(tester, invoice(paid: true), isAdmin: false);

    await scaffold.openModal(tester, find.text('FAC-2026-001'));
    expect(find.text('Mark as paid'), findsNothing);
    expect(find.text('Delete invoice'), findsNothing);

    await scaffold.tapInModal(tester, find.text('Mark as received'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);

    verify(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdReceivedPatch(
        invoiceId: 'inv-1',
      ),
    ).called(1);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused delete reports the failure, not the deletion', (
    tester,
  ) async {
    stubInvoice(scaffold);
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdDelete(
        invoiceId: any(named: 'invoiceId'),
      ),
    ).thenThrow(Exception('delete refused'));
    await mount(tester, invoice());

    await scaffold.openModal(tester, find.text('FAC-2026-001'));
    await scaffold.tapInModal(tester, find.text('Delete invoice'));
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 6);

    // The card answers with its own message, not the raw exception: that is
    // what a user reads, so that is what this pins.
    expect(
      anyVisibleTextContains(tester, 'Error while deleting'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    expect(anyVisibleTextContains(tester, 'Successfully deleted'), isFalse);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused "mark received" does not claim the invoice moved', (
    tester,
  ) async {
    stubInvoice(scaffold);
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdReceivedPatch(
        invoiceId: any(named: 'invoiceId'),
      ),
    ).thenThrow(Exception('received refused'));
    await mount(tester, invoice(paid: true), isAdmin: false);

    await scaffold.openModal(tester, find.text('FAC-2026-001'));
    await scaffold.tapInModal(tester, find.text('Mark as received'));
    // The card closes its own sheet and opens the confirmation, so the confirm
    // button only exists once that swap has been pumped.
    await settle(tester, frames: 8);
    await scaffold.tapInModal(tester, find.text('Confirm'));
    await settle(tester, frames: 8);

    expect(
      anyVisibleTextContains(tester, 'Error while updating the status'),
      isTrue,
      reason: 'toasts on screen: ${visibleTexts(tester)}',
    );
    expect(anyVisibleTextContains(tester, 'Successfully modified'), isFalse);
    await scaffold.drainToast(tester);
  });
}
