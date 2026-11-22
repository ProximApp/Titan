import 'package:flutter_test/flutter_test.dart';
import 'package:titan/event/tools/functions.dart';

void main() {
  group('formatDelayToToday', () {
    test('covers the day granularity', () {
      final now = DateTime(2026, 6, 1, 12);
      expect(formatDelayToToday(now, now), "Aujourd'hui");
      expect(
        formatDelayToToday(now.add(const Duration(days: 1)), now),
        'Demain',
      );
      expect(
        formatDelayToToday(now.add(const Duration(days: 10)), now),
        'Dans 10 jours',
      );
    });

    test('reports months for a delay past a month but under a year', () {
      final now = DateTime(2026, 1, 1);
      expect(formatDelayToToday(DateTime(2026, 3, 1), now), 'Dans 2 mois');
      expect(formatDelayToToday(DateTime(2026, 12, 1), now), 'Dans 11 mois');
    });

    test('reports years once the delay reaches a full year', () {
      final now = DateTime(2026, 1, 1);
      expect(formatDelayToToday(DateTime(2027, 1, 1), now), 'Dans 1 ans');
      expect(formatDelayToToday(DateTime(2028, 6, 1), now), 'Dans 2 ans');
    });
  });

  group('date helpers', () {
    test('processDateOnlyHour pads the hour and minute', () {
      expect(processDateOnlyHour(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('mergeDates keeps the day and takes the time', () {
      final merged = mergeDates(
        DateTime(2026, 3, 14),
        DateTime(2000, 1, 1, 9, 5),
      );
      expect(merged, DateTime(2026, 3, 14, 9, 5));
    });

    test('dayDifference counts whole days', () {
      expect(dayDifference(DateTime(2026, 1, 1), DateTime(2026, 1, 11)), 10);
    });
  });
}
