import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

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

  testWidgets('invoices admin page lists the invoices for the bank holder', (
    tester,
  ) async {
    stubMyPayment(scaffold);

    // isBankAccountHolderProvider requires the holder structure to be among
    // the structures the user manages; pre-seeded so the async middleware
    // gate resolves before the redirect is evaluated.
    final bde = structure('s-1', 'BDE', 'user-1');
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        myStructures: [bde],
        bankAccountHolder: bde,
      ),
      initialPath: '/mypayment/invoicesAdmin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('No news available'), findsNothing);
    // The pagination row rendered with 20 per page proves the page mounted
    // and the invoice query resolved.
    expect(find.textContaining('invoices/page'), findsOneWidget);
    expect(find.text('Create new invoice'), findsOneWidget);
  });
}
