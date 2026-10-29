import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/invoice_list_provider.dart';
import 'package:titan/mypayment/providers/my_history_provider.dart';
import 'package:titan/mypayment/providers/selected_interval_provider.dart';
import 'package:titan/mypayment/providers/selected_transactions_provider.dart';
import 'package:titan/mypayment/ui/components/invoice_card.dart';
import 'package:titan/mypayment/ui/pages/stats_page/sum_up_card.dart';
import 'package:titan/mypayment/ui/pages/stats_page/sum_up_chart.dart';
import 'package:titan/mypayment/ui/pages/store_stats_page/interval_selector.dart';
import 'package:titan/tools/ui/styleguide/button.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/mock_openapi.dart';

/// Widget-level tests for the mypayment surfaces the page shells never
/// render directly: the month chart, the interval picker and the invoice
/// card's admin/user flows.
class _FakeHistoryNotifier extends MyHistoryNotifier {
  _FakeHistoryNotifier(this.histories);

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

  /// Pumps fixed frames instead of pumpAndSettle: a success toast runs a
  /// progress animation that never settles. The final long jump flushes the
  /// toast auto-close timer so no Timer outlives the test.
  Future<void> pumpFrames(WidgetTester tester, {int frames = 12}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  History history({
    required String id,
    enums.HistoryType type = enums.HistoryType.refund,
    enums.TransactionStatus status = enums.TransactionStatus.confirmed,
    String wallet = 'BDE',
    int total = 1000,
    DateTime? creation,
  }) => History.empty().copyWith(
    id: id,
    type: type,
    status: status,
    otherWalletName: wallet,
    total: total,
    creation: creation ?? DateTime(2026, 10, 5),
  );

  Invoice invoice({
    String id = 'inv-1',
    bool paid = false,
    bool received = false,
  }) => Invoice.empty().copyWith(
    id: id,
    reference: 'FA-2026-001',
    paid: paid,
    received: received,
    total: 1250,
    structure: Structure.empty().copyWith(name: 'BDE'),
  );

  group('SumUpCard', () {
    testWidgets('renders the pinned title and amount', (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        const SumUpCard(
          title: 'Received',
          amount: '12,50 ʍ',
          color: Color(0xFF017F80),
          darkColor: Color(0xFF006667),
          shadowColor: Color(0x33002C2D),
        ),
        container,
      );

      expect(find.text('Received'), findsOneWidget);
      expect(find.text('12,50 ʍ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SumUpChart', () {
    final month = DateTime(2026, 10, 1);

    ProviderContainer containerWithHistory(List<History> histories) {
      // makeContainer cannot take extra overrides, and the chart only needs
      // the fake history on top of the locale/prefs defaults.
      final container = ProviderContainer(
        overrides: [
          myHistoryProvider.overrideWith(() => _FakeHistoryNotifier(histories)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    testWidgets('groups the month transfers and totals per side', (
      tester,
    ) async {
      final container = containerWithHistory([
        // Credited side: a top-up and a request from Alice.
        history(
          id: 'h1',
          type: enums.HistoryType.directTransfer,
          wallet: 'ignored',
          total: 500,
        ),
        history(
          id: 'h2',
          type: enums.HistoryType.requestTransfer,
          wallet: 'Alice',
          total: 300,
        ),
        // Spent side: a refund line at BDE.
        history(id: 'h3', wallet: 'BDE', total: 1250),
        // Filtered out: another status, another month.
        history(
          id: 'h4',
          status: enums.TransactionStatus.pending,
          wallet: 'BDE',
        ),
        history(id: 'h5', creation: DateTime(2026, 9, 5), wallet: 'BDE'),
      ]);

      await scaffold.pumpWidgetApp(
        tester,
        SumUpChart(currentMonth: month),
        container,
        locale: const Locale('en', 'US'),
        appFonts: true,
      );

      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tapping a summary flips to its page and re-selects the transactions.
      await tester.tap(
        find
            .ancestor(
              of: find.text('Received'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await pumpFrames(tester);
      final selected = container.read(
        selectedTransactionsProvider(month).notifier,
      );
      expect(selected.state.map((t) => t.id), containsAll(['h1', 'h2']));

      await tester.tap(
        find
            .ancestor(
              of: find.text('Spent'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the empty month placeholder', (tester) async {
      final container = containerWithHistory([
        history(id: 'h5', creation: DateTime(2026, 9, 5), wallet: 'BDE'),
      ]);

      await scaffold.pumpWidgetApp(
        tester,
        SumUpChart(currentMonth: month),
        container,
        locale: const Locale('en', 'US'),
        appFonts: true,
      );

      expect(find.textContaining('transaction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('IntervalSelector', () {
    testWidgets('picks a new start day and reloads the history', (
      tester,
    ) async {
      final repo = scaffold.repository;
      when(
        () => repo.mypaymentStoresStoreIdHistoryGet(
          storeId: '',
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => repo.okList<History>());

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      final initial = container.read(selectedIntervalProvider);

      await scaffold.pumpWidgetApp(
        tester,
        const IntervalSelector(),
        container,
        locale: const Locale('en', 'US'),
        // The four date/time chips plus the arrow overflow a 360px row.
        surface: const Size(800, 640),
      );

      final startLabel = DateFormat.yMd('fr_FR').format(initial.start);
      await tester.tap(find.text(startLabel).first);
      await tester.pumpAndSettle();

      // The date picker opens on the current selection; accepting today
      // (always inside the [firstDate, lastDate] window) rewrites the start.
      final targetDay = DateTime.now().day;
      await tester.tap(find.text('$targetDay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await pumpFrames(tester);

      expect(container.read(selectedIntervalProvider).start.day, targetDay);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancelling the start picker leaves the interval alone', (
      tester,
    ) async {
      final repo = scaffold.repository;
      when(
        () => repo.mypaymentStoresStoreIdHistoryGet(
          storeId: '',
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => repo.okList<History>());

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      final initial = container.read(selectedIntervalProvider);

      await scaffold.pumpWidgetApp(
        tester,
        const IntervalSelector(),
        container,
        locale: const Locale('en', 'US'),
        // The four date/time chips plus the arrow overflow a 360px row.
        surface: const Size(800, 640),
      );

      final startLabel = DateFormat.yMd('fr_FR').format(initial.start);
      await tester.tap(find.text(startLabel).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await pumpFrames(tester);

      expect(container.read(selectedIntervalProvider).start, initial.start);
      expect(tester.takeException(), isNull);
    });

    testWidgets('picking a start time rewrites the start hour', (tester) async {
      final repo = scaffold.repository;
      when(
        () => repo.mypaymentStoresStoreIdHistoryGet(
          storeId: '',
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => repo.okList<History>());

      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      final initial = container.read(selectedIntervalProvider);

      await scaffold.pumpWidgetApp(
        tester,
        const IntervalSelector(),
        container,
        locale: const Locale('en', 'US'),
        // The four date/time chips plus the arrow overflow a 360px row.
        surface: const Size(800, 640),
      );

      final timeLabel = DateFormat.Hm('fr_FR').format(initial.start);
      await tester.tap(find.text(timeLabel).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await pumpFrames(tester);

      expect(
        container.read(selectedIntervalProvider).start.hour,
        initial.start.hour,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('InvoiceCard', () {
    void stubPdf(MockOpenapi repo, String invoiceId) {
      when(() => repo.mypaymentInvoicesInvoiceIdGet(invoiceId: invoiceId))
          .thenAnswer(
            (_) async => chopper.Response(http.Response('pdf', 200), null),
          );
    }

    testWidgets('an admin marks an unpaid invoice as paid', (tester) async {
      final repo = scaffold.repository;
      stubPdf(repo, 'inv-1');
      when(
        () => repo.mypaymentInvoicesInvoiceIdPaidPatch(
          invoiceId: 'inv-1',
          paid: any(named: 'paid'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      var refreshed = 0;
      final container = scaffold.makeContainer(invoices: [invoice()]);
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        InvoiceCard(
          invoice: invoice(),
          isAdmin: true,
          invoicesRefresher: () => refreshed++,
        ),
        container,
        locale: const Locale('en', 'US'),
      );

      expect(find.text('Pending'), findsOneWidget);

      await tester.tap(find.text('FA-2026-001').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark as paid'));
      await pumpFrames(tester);

      expect(refreshed, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an admin deletes an unpaid invoice after confirming', (
      tester,
    ) async {
      final repo = scaffold.repository;
      stubPdf(repo, 'inv-1');
      when(() => repo.mypaymentInvoicesInvoiceIdDelete(invoiceId: 'inv-1'))
          .thenAnswer((_) async => repo.okVoid());

      final container = scaffold.makeContainer(invoices: [invoice()]);
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        InvoiceCard(
          invoice: invoice(),
          isAdmin: true,
          invoicesRefresher: () {},
        ),
        container,
        locale: const Locale('en', 'US'),
      );

      await tester.tap(find.text('FA-2026-001').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Button).last);
      await tester.pumpAndSettle();
      // The confirmation modal is up: its confirm button is the last one.
      await tester.tap(find.byType(Button).last);
      await pumpFrames(tester);

      expect(container.read(invoiceListProvider).value ?? [], isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a user marks a paid invoice as received', (tester) async {
      final repo = scaffold.repository;
      stubPdf(repo, 'inv-1');
      when(
        () => repo.mypaymentInvoicesInvoiceIdReceivedPatch(invoiceId: 'inv-1'),
      ).thenAnswer((_) async => repo.okVoid());

      var refreshed = 0;
      final container = scaffold.makeContainer(invoices: [invoice(paid: true)]);
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        InvoiceCard(
          invoice: invoice(paid: true),
          isAdmin: false,
          invoicesRefresher: () => refreshed++,
        ),
        container,
        locale: const Locale('en', 'US'),
      );

      expect(find.text('Paid'), findsOneWidget);

      await tester.tap(find.text('FA-2026-001').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Button).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Button).last);
      await pumpFrames(tester);

      expect(refreshed, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a received invoice shows its received label', (tester) async {
      final repo = scaffold.repository;
      stubPdf(repo, 'inv-1');

      final container = scaffold.makeContainer(
        invoices: [invoice(paid: true, received: true)],
      );
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        InvoiceCard(
          invoice: invoice(paid: true, received: true),
          isAdmin: false,
          invoicesRefresher: () {},
        ),
        container,
        locale: const Locale('en', 'US'),
      );

      expect(find.text('Received'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
