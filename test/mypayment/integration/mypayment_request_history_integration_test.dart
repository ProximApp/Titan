import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

Request$ request(String id, String name, RequestStatus status, int total) =>
    Request$(
      id: id,
      walletId: 'wallet-1',
      creation: DateTime(2026, 1, 5, 12, 30),
      expirationDate: DateTime(2026, 12, 31),
      total: total,
      storeId: 'store-1',
      name: name,
      module: 'mypayment',
      objectId: 'object-1',
      status: status,
    );

void stubMyPayment(IntegrationScaffold scaffold, {List<Request$>? requests}) {
  when(
    () => scaffold.repository.mypaymentRequestsGet(used: true),
  ).thenAnswer((_) async => chopperListResponse(requests ?? <Request$>[]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('request history page lists the past requests', (tester) async {
    stubMyPayment(
      scaffold,
      requests: [request('r-1', 'Soda', RequestStatus.accepted, 500)],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('Activities'), findsOneWidget);
    // The request card renders the request name and its amount (fr locale).
    expect(find.text('Soda'), findsOneWidget);
    expect(find.textContaining('5,00'), findsWidgets);
  });

  testWidgets('request history page shows the empty message with no request', (
    tester,
  ) async {
    stubMyPayment(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('No payment requests'), findsOneWidget);
  });
}
