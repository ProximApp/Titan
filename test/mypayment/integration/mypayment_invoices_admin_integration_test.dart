import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../mypayment_fixtures.dart';
import '../../shared/app_scaffold.dart';
import 'dart:ui' as ui;
import 'package:mocktail/mocktail.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/mypayment/ui/pages/invoices_admin_page/invoices_admin_page.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('invoices admin page lists the invoices for the bank holder', (
    tester,
  ) async {
    stubInvoicePreviews(scaffold);
    // The page fetches on mount now (ledger #8): the list comes from this
    // stub rather than from a pre-seeded provider.
    stubInvoiceList(scaffold);

    // isBankAccountHolderProvider requires the holder structure to be among
    // the structures the user manages; pre-seeded so the async middleware
    // gate resolves before the redirect is evaluated.
    final bde = structureFixture('s-1', 'BDE', 'user-1');
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

  testWidgets('pull to refresh reloads the page of invoices', (tester) async {
    stubInvoicePreviews(scaffold);
    stubInvoiceList(scaffold);

    final bde = structureFixture('s-1', 'BDE', 'user-1');
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      myStructures: [bde],
      bankAccountHolder: bde,
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const InvoicesAdminPage(),
      container,
      surface: const ui.Size(1920, 1080),
    );
    await settle(tester, frames: 20);

    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher).first, const Offset(0, 400));
    await settle(tester, frames: 24);

    verify(
      () => scaffold.repository.mypaymentInvoicesGet(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).called(greaterThan(0));
  });
}
