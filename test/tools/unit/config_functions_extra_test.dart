import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/functions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getMinimalHyperionVersion', () {
    test('reads the declared minimal hyperion version from pubspec', () async {
      expect(await getMinimalHyperionVersion(), '6.0.0');
    });
  });

  group('formatRecurrenceRule', () {
    test('labels an all-day event without recurrence', () {
      final text = formatRecurrenceRule(
        DateTime(2026, 5, 1, 9),
        DateTime(2026, 5, 1, 18),
        '',
        true,
        'fr',
      );
      expect(text, contains('toute la journée'));
    });

    test('labels a timed event without recurrence', () {
      final text = formatRecurrenceRule(
        DateTime(2026, 5, 1, 9),
        DateTime(2026, 5, 1, 18),
        '',
        false,
        'fr',
      );
      expect(text, contains('de 09:00 à 18:00'));
    });
  });
}
