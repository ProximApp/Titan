import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/my_history_provider.dart';
import 'package:titan/mypayment/ui/pages/stats_page/month_bar.dart';
import 'package:titan/tools/providers/locale_notifier.dart';

import '../../shared/app_scaffold.dart';

class _FakeHistoryNotifier extends MyHistoryNotifier {
  _FakeHistoryNotifier(this.histories);

  final List<History> histories;

  @override
  AsyncValue<List<History>> build() => AsyncValue.data(histories);
}

/// The stats page's month header: it folds the month's confirmed history into
/// one signed total. Three term kinds feed the sum (a direct transaction and a
/// refund count as money out, a request as money in) plus the state where the
/// history has not resolved yet.
void main() {
  late IntegrationScaffold scaffold;
  final month = DateTime(2026, 10, 1);

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  History history({
    required String id,
    enums.HistoryType type = enums.HistoryType.requestTransfer,
    enums.TransactionStatus status = enums.TransactionStatus.confirmed,
    int total = 1000,
    int? refundTotal,
    DateTime? creation,
  }) => History.empty().copyWith(
    id: id,
    type: type,
    status: status,
    total: total,
    refund: refundTotal == null
        ? null
        : HistoryRefund.empty().copyWith(total: refundTotal),
    creation: creation ?? DateTime(2026, 10, 5),
  );

  ProviderContainer containerWithHistory(List<History> histories) {
    final container = ProviderContainer(
      overrides: [
        myHistoryProvider.overrideWith(() => _FakeHistoryNotifier(histories)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('a positive month prints a signed total', (tester) async {
    final container = containerWithHistory([history(id: 'h1', total: 300)]);

    await scaffold.pumpWidgetApp(
      tester,
      MonthBar(currentMonth: month),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    // The header carries the month's name in the app's own locale (the
    // provider's, not the widget test's) and the plus sign the total earns.
    final monthLabel = DateFormat.yMMMM(
      container.read(localeProvider).toString(),
    ).format(month);
    expect(find.textContaining(monthLabel), findsOneWidget);
    expect(find.textContaining('+'), findsOneWidget);
    expect(find.textContaining('ʍ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spending and refunds subtract from the month', (tester) async {
    final container = containerWithHistory([
      // Money out: the payment itself.
      history(id: 'h1', type: enums.HistoryType.directTransaction, total: 500),
      // A refund's net is the payment minus what came back.
      history(
        id: 'h2',
        type: enums.HistoryType.refund,
        total: 1000,
        refundTotal: 200,
      ),
      // Ignored: neither confirmed nor refunded.
      history(id: 'h3', status: enums.TransactionStatus.pending, total: 99999),
      // Ignored: another month.
      history(id: 'h4', creation: DateTime(2026, 9, 5), total: 99999),
    ]);

    await scaffold.pumpWidgetApp(
      tester,
      MonthBar(currentMonth: month),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    // 500 out plus an 800 net refund leaves the month negative. Had the
    // pending or the September row counted, their 99999 would have flipped it
    // positive, so the sign alone proves both were filtered.
    expect(find.textContaining('-'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unresolved history totals zero', (tester) async {
    // No override: the real notifier starts loading and its backend call is
    // left unstubbed, so the header takes the orElse arm.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      MonthBar(currentMonth: month),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    expect(find.textContaining('ʍ'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
