import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/ui/pages/store_stats_page/interval_selector.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('store stats page renders the summary of the store history', (
    tester,
  ) async {
    stubStoreStats(
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
    stubStoreStats(scaffold);

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
