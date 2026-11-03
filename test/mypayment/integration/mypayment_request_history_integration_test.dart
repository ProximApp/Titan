import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/mypayment/ui/pages/request_history_page/request_history_page.dart';

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

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('request history page lists the past requests', (tester) async {
    stubUsedRequests(
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
    stubUsedRequests(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/mypayment/requestHistory',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('No payment requests'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the paid requests', (tester) async {
    when(
      () => scaffold.repository.mypaymentRequestsGet(
        used: any(named: 'used'),
      ),
    ).thenAnswer((_) async => chopperListResponse(<Request$>[]));

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(tester, const RequestHistoryPage(), container);
    await settle(tester, frames: 20);

    clearInteractions(scaffold.repository);
    await tester.drag(find.byType(Refresher).first, const Offset(0, 400));
    await settle(tester, frames: 24);

    verify(() => scaffold.repository.mypaymentRequestsGet(used: true)).called(1);
  });
}
