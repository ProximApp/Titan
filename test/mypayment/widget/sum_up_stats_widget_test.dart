import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/my_history_provider.dart';
import 'package:titan/mypayment/ui/pages/stats_page/sum_up_card.dart';
import 'package:titan/mypayment/ui/pages/stats_page/sum_up_chart.dart';
import 'package:titan/tools/providers/locale_notifier.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the stats-page summary: `SumUpCard` (the
/// pinned bubble with its one-line title) and `SumUpChart` (the monthly
/// received/spent split fed by the wallet history).
class _HistoryNotifier extends MyHistoryNotifier {
  _HistoryNotifier(this.histories);

  final List<History> histories;

  @override
  AsyncValue<List<History>> build() => AsyncValue.data(histories);
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Bounded pumps: the pie chart animates, so pumpAndSettle would hang.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  History history({
    required TransactionStatus status,
    required HistoryType type,
    required DateTime creation,
    required int total,
    String name = 'Caisse',
  }) => History.empty().copyWith(
    id: 'h-$total-$name',
    status: status,
    type: type,
    creation: creation,
    total: total,
    otherWalletName: name,
  );

  ProviderContainer containerWith(List<History> histories) {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        myHistoryProvider.overrideWith(() => _HistoryNotifier(histories)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('SumUpCard renders and keeps a long title on one line', (
    tester,
  ) async {
    final container = containerWith(const []);
    await scaffold.pumpWidgetApp(
      tester,
      const Row(
        children: [
          SumUpCard(
            title: 'Buvette',
            amount: '12.34 ʍ',
            color: Colors.teal,
            darkColor: Colors.black,
            shadowColor: Colors.black26,
          ),
          SumUpCard(
            title: 'An association title that is far too long to ever fit',
            amount: '0.00 ʍ',
            color: Colors.teal,
            darkColor: Colors.black,
            shadowColor: Colors.black26,
          ),
        ],
      ),
      container,
    );

    expect(find.text('Buvette'), findsOneWidget);
    expect(find.text('12.34 ʍ'), findsOneWidget);
    expect(find.textContaining('far too long'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the chart splits the confirmed month into received and spent', (
    tester,
  ) async {
    final now = DateTime.now();
    final container = containerWith([
      // Received: a direct top-up plus a requested transfer.
      history(
        status: TransactionStatus.confirmed,
        type: HistoryType.directTransfer,
        creation: now,
        total: 1500,
        name: 'ignored',
      ),
      history(
        status: TransactionStatus.refunded,
        type: HistoryType.requestTransfer,
        creation: now,
        total: 500,
        name: 'Sam',
      ),
      // Spent in the current month.
      history(
        status: TransactionStatus.confirmed,
        type: HistoryType.directTransaction,
        creation: now,
        total: 1234,
        name: 'Buvette',
      ),
      // Another month: filtered out of both totals.
      history(
        status: TransactionStatus.confirmed,
        type: HistoryType.directTransaction,
        creation: DateTime(now.year - 1, now.month, now.day),
        total: 9999,
        name: 'Old',
      ),
    ]);

    await scaffold.pumpWidgetApp(
      tester,
      SumUpChart(currentMonth: DateTime(now.year, now.month)),
      container,
    );
    await pumpFrames(tester);

    final formatter = NumberFormat.currency(
      locale: container.read(localeProvider).toString(),
      symbol: 'ʍ',
    );
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.text(formatter.format(20.0)), findsOneWidget);
    expect(find.text(formatter.format(12.34)), findsOneWidget);
    // The current page holds the received pie chart.
    expect(find.byType(PieChart), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty month shows the no-transaction message', (
    tester,
  ) async {
    final container = containerWith(const []);
    final now = DateTime.now();

    await scaffold.pumpWidgetApp(
      tester,
      SumUpChart(currentMonth: DateTime(now.year, now.month)),
      container,
    );
    await pumpFrames(tester);

    expect(find.text('No transactions for this month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
