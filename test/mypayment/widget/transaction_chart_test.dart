import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/my_history_provider.dart';
import 'package:titan/mypayment/providers/selected_transactions_provider.dart';
import 'package:titan/mypayment/ui/pages/stats_page/transaction_chart.dart';

import '../../shared/app_scaffold.dart';

/// Behaviour tests for [TransactionChart] — the per-store pie the stats page
/// draws under `SumUpChart`.
///
/// The card sweep already mounts this widget for layout, but never drives it:
/// no test reached the empty-month placeholder, the colour-variation branch
/// for the second wallet, or the touch callback that reseeds
/// `selectedTransactionsProvider`. Those are the three things this file pins.
class _FakeHistoryNotifier extends MyHistoryNotifier {
  _FakeHistoryNotifier(this.histories);

  final List<History> histories;

  @override
  AsyncValue<List<History>> build() => AsyncValue.data(histories);
}

void main() {
  late IntegrationScaffold scaffold;
  final month = DateTime(2026, 10, 1);

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  History history({
    required String id,
    String wallet = 'BDE',
    int total = 1000,
    enums.HistoryType type = enums.HistoryType.refund,
  }) => History.empty().copyWith(
    id: id,
    type: type,
    status: enums.TransactionStatus.confirmed,
    otherWalletName: wallet,
    total: total,
    creation: DateTime(2026, 10, 5),
  );

  ProviderContainer containerWith(List<History> histories) {
    final container = ProviderContainer(
      overrides: [
        myHistoryProvider.overrideWith(() => _FakeHistoryNotifier(histories)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('an empty month renders the placeholder instead of a chart', (
    tester,
  ) async {
    final container = containerWith([history(id: 'h1')]);

    await scaffold.pumpWidgetApp(
      tester,
      TransactionChart(transactionPerStore: const {}, currentMonth: month),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    expect(find.text('No transaction'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one section per store, each labelled with its wallet', (
    tester,
  ) async {
    final container = containerWith([
      history(id: 'h1', total: 1500),
      history(
        id: 'h2',
        wallet: 'Alice',
        total: 500,
        type: enums.HistoryType.directTransfer,
      ),
    ]);

    await scaffold.pumpWidgetApp(
      tester,
      TransactionChart(
        currentMonth: month,
        transactionPerStore: {
          'BDE': [history(id: 'h1', total: 1500)],
          'Alice': [
            history(
              id: 'h2',
              wallet: 'Alice',
              total: 500,
              type: enums.HistoryType.directTransfer,
            ),
          ],
        },
      ),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    // Two wallets means the second one goes through generateColorVariations;
    // both badges must still render, each titled with its wallet name.
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('touching a section reseeds the selected transactions', (
    tester,
  ) async {
    final bde = history(id: 'h1', total: 1500);
    final alice = history(
      id: 'h2',
      wallet: 'Alice',
      total: 500,
      type: enums.HistoryType.directTransfer,
    );
    final container = containerWith([bde, alice]);

    await scaffold.pumpWidgetApp(
      tester,
      TransactionChart(
        currentMonth: month,
        transactionPerStore: {
          'BDE': [bde],
          'Alice': [alice],
        },
      ),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    final chart = find.byType(PieChart);
    final center = tester.getCenter(chart);

    // A touch that lands in the donut hole has no section: fl_chart answers
    // -1, and the widget's callback then hands EVERY transaction to the
    // selection provider rather than one wallet's slice.
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    final selected = container.read(selectedTransactionsProvider(month));
    expect(selected.map((t) => t.id), containsAll(['h1', 'h2']));
    expect(tester.takeException(), isNull);
  });
}
