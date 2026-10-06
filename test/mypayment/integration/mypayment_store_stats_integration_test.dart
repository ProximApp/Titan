import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/ui/pages/store_stats_page/interval_selector.dart';

import '../../shared/app_scaffold.dart';

void stubMyPayment(IntegrationScaffold scaffold, {List<History>? historyList}) {
  when(
    () => scaffold.repository.mypaymentUsersMeStoresGet(),
  ).thenAnswer((_) async => chopperListResponse([myPaymentStore]));
  when(
    () => scaffold.repository.mypaymentStoresStoreIdHistoryGet(
      storeId: 'store-1',
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => chopperListResponse(historyList ?? <History>[]));
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('store stats page renders the summary of the store history', (
    tester,
  ) async {
    stubMyPayment(
      scaffold,
      historyList: [history('h-1', HistoryDirection.debited, 250)],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/storeStats',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The interval selector and the summary card render.
    expect(find.textContaining('ʍ'), findsWidgets);
  });

  testWidgets('store stats page renders with an empty history', (tester) async {
    stubMyPayment(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/storeStats',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // With no transaction the summary card collapses to a SizedBox; the
    // interval selector above it is what proves the page mounted.
    expect(find.byType(IntervalSelector), findsOneWidget);
  });
}
