import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

Invoice invoice(String id, String reference, Structure structure, int total) =>
    Invoice.empty().copyWith(
      id: id,
      reference: reference,
      structureId: structure.id,
      creation: DateTime(2026, 1, 5),
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
      total: total,
      structure: structure,
    );

void stubMyPayment(IntegrationScaffold scaffold) {
  // InvoiceCard previews the invoice PDF on build.
  when(
    () => scaffold.repository.mypaymentInvoicesInvoiceIdGet(
      invoiceId: any(named: 'invoiceId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopper.Response(http.Response.bytes([1, 2, 3], 200), [1, 2, 3]),
  );
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('structure invoices page lists the invoices of the structure', (
    tester,
  ) async {
    final bde = structure('structure-1', 'BDE', 'user-1');
    stubMyPayment(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        // Pre-seeded so the async AdminMiddleware gate (the user manages the
        // structure) resolves before the redirect is evaluated.
        myStructures: [bde],
        selectedStructure: bde,
        // The real notifier never fetches on mount (see README known bugs);
        // the invoice list is pre-seeded instead.
        invoices: [invoice('inv-1', 'FA-2026-001', bde, 1500)],
      ),
      initialPath: '/mypayment/invoicesStructure',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('FA-2026-001'), findsOneWidget);
    // The invoice is neither paid nor received.
    expect(find.text('Pending'), findsOneWidget);
    // The pagination row renders with 20 per page.
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('structure invoices page renders empty with no invoice', (
    tester,
  ) async {
    stubMyPayment(scaffold);
    final bde = structure('structure-1', 'BDE', 'user-1');

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        myStructures: [bde],
        selectedStructure: bde,
      ),
      initialPath: '/mypayment/invoicesStructure',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('FA-2026-001'), findsNothing);
    expect(find.text('20'), findsOneWidget);
  });
}
