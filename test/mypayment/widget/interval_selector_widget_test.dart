import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/selected_interval_provider.dart';
import 'package:titan/mypayment/ui/pages/store_stats_page/interval_selector.dart';
import 'package:titan/tools/providers/locale_notifier.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for `IntervalSelector`: the four pills render the
/// selected interval in the app locale, and every date/time pick updates
/// the interval and reloads the store history through the real API call.
/// The store stays empty, so the only history loads are the ones the pills
/// trigger.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Bounded pumps: pickers animate and the history load answers async.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the four pills pick dates and times and reload the history', (
    tester,
  ) async {
    final repo = scaffold.repository;
    when(
      () => repo.mypaymentStoresStoreIdHistoryGet(
        storeId: any(named: 'storeId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => repo.okList<History>());

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const IntervalSelector(),
      container,
      locale: const Locale('en', 'US'),
    );

    final locale = container.read(localeProvider).toString();
    String yMd(DateTime d) => DateFormat.yMd(locale).format(d);
    String hm(DateTime d) => DateFormat.Hm(locale).format(d);

    // The pills show the interval formatted in the app locale: start date,
    // start time, end date, end time (the arrow sits between them). Every
    // pick mutates the interval, so the pill labels are re-read before each
    // tap; the start pills come first in the row, so the start labels use
    // `.first` and the end labels `.last` even when both sides show the
    // same string.
    final interval = container.read(selectedIntervalProvider);
    expect(find.text(yMd(interval.start)).first, findsOneWidget);
    expect(find.text(hm(interval.start)).first, findsOneWidget);
    expect(find.text(yMd(interval.end)).last, findsOneWidget);
    expect(find.text(hm(interval.end)).last, findsOneWidget);

    // Start date: the picker defaults to the interval start (a month back),
    // so day 10 always exists in the displayed month.
    await tester.tap(find.text(yMd(interval.start)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await pumpFrames(tester);
    expect(container.read(selectedIntervalProvider).start.day, 10);

    // Start time: OK re-applies the initial clock time.
    final start = container.read(selectedIntervalProvider).start;
    await tester.tap(find.text(hm(start)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await pumpFrames(tester);

    // End date: accepting the preselected day keeps the day and zeroes the
    // time through the midnight conversion.
    final beforeEnd = container.read(selectedIntervalProvider).end;
    await tester.tap(find.text(yMd(beforeEnd)).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await pumpFrames(tester);
    expect(
      container.read(selectedIntervalProvider).end.day,
      DateTime.now().day,
    );

    // End time: OK re-applies the (now midnight) clock time.
    final end = container.read(selectedIntervalProvider).end;
    await tester.tap(find.text(hm(end)).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await pumpFrames(tester);

    // One history load per accepted pick (the cancel path below proves the
    // picker itself does not fire one).
    verify(
      () => repo.mypaymentStoresStoreIdHistoryGet(
        storeId: any(named: 'storeId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).called(4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the picker leaves the interval untouched', (
    tester,
  ) async {
    final repo = scaffold.repository;
    when(
      () => repo.mypaymentStoresStoreIdHistoryGet(
        storeId: any(named: 'storeId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => repo.okList<History>());

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const IntervalSelector(),
      container,
      locale: const Locale('en', 'US'),
    );

    final before = container.read(selectedIntervalProvider);
    final startDate = DateFormat.yMd(container.read(localeProvider).toString())
        .format(before.start);

    await tester.tap(find.text(startDate).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await pumpFrames(tester);

    expect(container.read(selectedIntervalProvider), before);
    verifyNever(
      () => repo.mypaymentStoresStoreIdHistoryGet(
        storeId: any(named: 'storeId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
