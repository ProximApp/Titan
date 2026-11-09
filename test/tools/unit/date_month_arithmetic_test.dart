import 'package:flutter_test/flutter_test.dart';
import 'package:titan/mypayment/class/history_interval.dart';
import 'package:titan/tools/functions.dart';

/// The month-boundary sweep's ratchet for category (b): date-plus-offset
/// arithmetic that must not normalize into the next month.
///
/// `DateTime(year, month ± 1, day)` NORMALIZES instead of failing. Before the
/// fix, `HistoryInterval.currentMonth()` on 31 December asked for
/// `DateTime(2026, 11, 31)` and got 1 December — the "last month" interval
/// started one day after it should have, and February did the same on the
/// 29th/30th/31st. `sameDayYearsFrom` closes the same hole on the date
/// picker's one-year bounds, where 29 February plus a year became 1 March.
///
/// Every case asserts the resulting MONTH, not merely that the call returns:
/// a normalization bug returns a perfectly valid DateTime.
void main() {
  group('HistoryInterval.currentMonth clamps the month end', () {
    test('31 December starts on 30 November, not 1 December', () {
      final interval = HistoryInterval.currentMonth(
        now: DateTime(2026, 12, 31),
      );
      expect(interval.start.year, 2026);
      expect(interval.start.month, 11, reason: 'the bug normalized to 12');
      expect(interval.start.day, 30);
      expect(interval.end.month, 12);
      expect(interval.end.day, 31);
    });

    test('31 January starts on 31 December of the previous year', () {
      final interval = HistoryInterval.currentMonth(now: DateTime(2026, 1, 31));
      expect(interval.start.year, 2025);
      expect(interval.start.month, 12);
      expect(interval.start.day, 31);
    });

    test('28 February starts on 28 January', () {
      final interval = HistoryInterval.currentMonth(now: DateTime(2026, 2, 28));
      expect(interval.start.year, 2026);
      expect(interval.start.month, 1);
      expect(interval.start.day, 28);
    });

    test('the clamp follows February into a leap year', () {
      final interval = HistoryInterval.currentMonth(now: DateTime(2024, 3, 31));
      expect(interval.start.month, 2, reason: 'the bug normalized to 3');
      expect(interval.start.day, 29);
    });

    test('a mid-month date is unchanged', () {
      final interval = HistoryInterval.currentMonth(now: DateTime(2026, 6, 15));
      expect(interval.start.month, 5);
      expect(interval.start.day, 15);
      expect(interval.end.hour, 23);
      expect(interval.end.minute, 59);
    });
  });

  group('sameDayYearsFrom clamps the date-picker year bounds', () {
    test('31 December survives a year forward', () {
      final result = sameDayYearsFrom(DateTime(2026, 12, 31), 1);
      expect(result.month, 12);
      expect(result.day, 31);
      expect(result.year, 2027);
    });

    test('31 January survives a year forward', () {
      final result = sameDayYearsFrom(DateTime(2026, 1, 31), 1);
      expect(result.month, 1);
      expect(result.day, 31);
    });

    test('28 February survives a year forward', () {
      final result = sameDayYearsFrom(DateTime(2026, 2, 28), 1);
      expect(result.month, 2);
      expect(result.day, 28);
    });

    test('29 February clamps to 28 February in a non-leap year', () {
      final result = sameDayYearsFrom(DateTime(2024, 2, 29), 1);
      expect(result.year, 2025);
      expect(result.month, 2, reason: 'the bug normalized to 1 March');
      expect(result.day, 28);
    });

    test('the backward bound clamps the same way', () {
      final result = sameDayYearsFrom(DateTime(2024, 2, 29), -1);
      expect(result.year, 2023);
      expect(result.month, 2, reason: 'the bug normalized to 1 March');
      expect(result.day, 28);
    });

    test('a mid-month date keeps its day in both directions', () {
      expect(sameDayYearsFrom(DateTime(2026, 6, 15), 1).day, 15);
      expect(sameDayYearsFrom(DateTime(2026, 6, 15), -1).day, 15);
    });
  });
}
