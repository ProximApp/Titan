import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('non bank holders are bounced away from the invoices admin', (
    tester,
  ) async {
    // Regression companion to the allowed-access case in
    // mypayment_invoices_admin_integration_test.dart: the AdminMiddleware
    // gate on /mypayment/invoicesAdmin must bounce a user who manages no
    // structure that is the bank account holder.
    //
    // NOTE: qlevar_router 1.12.4 only processes the init-path middleware
    // chain on the first navigation of the isolate; this file therefore
    // holds exactly one deep-link test (see the purchases test NOTE).
    when(
      () => scaffold.repository.mypaymentInvoicesInvoiceIdGet(
        invoiceId: any(named: 'invoiceId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopper.Response(http.Response.bytes([1, 2, 3], 200), [1, 2, 3]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/invoicesAdmin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The AdminMiddleware bounces non bank holders to the feed.
    expect(find.text('No news available'), findsOneWidget);
  });
}
