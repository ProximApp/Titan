import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/date_time_json.dart';

/// The API keeps every timestamp in UTC; the app keeps them local. These two
/// helpers are the only place that converts between the two.
void main() {
  group('dateTimeToJson', () {
    test('a local time is stored as UTC with the Z suffix', () {
      final local = DateTime(2026, 3, 4, 5, 6, 7);

      expect(dateTimeToJson(local), local.toUtc().toIso8601String());
      expect(dateTimeToJson(local), endsWith('Z'));
    });

    test('null stays null', () {
      expect(dateTimeToJson(null), isNull);
    });
  });

  group('dateTimeFromJson', () {
    test('a UTC string comes back as the same instant, local', () {
      final parsed = dateTimeFromJson('2026-03-04T05:06:07.000Z');

      expect(parsed.isUtc, isFalse);
      expect(
        parsed.isAtSameMomentAs(DateTime.utc(2026, 3, 4, 5, 6, 7)),
        isTrue,
        reason: 'the instant is unchanged, only the zone is',
      );
      expect(parsed, DateTime.parse('2026-03-04T05:06:07.000Z').toLocal());
    });

    test('a local string without a zone is read as the machine zone', () {
      final parsed = dateTimeFromJson('2026-03-04T05:06:07.000');

      expect(parsed, DateTime(2026, 3, 4, 5, 6, 7));
    });
  });
}
