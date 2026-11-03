import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/functions.dart';

/// The shared date-input parsers are fed from text fields, and the pickers
/// write a locale-formatted string that is not ISO-8601. An emptied field
/// used to reach `DateFormat.parse` and throw a `FormatException` — the
/// `Maybe` helper's own fallback threw again on the same input.
void main() {
  const locale = 'en_US';

  group('processDateBackWithHourMaybe', () {
    test('an empty field yields an empty string instead of throwing', () {
      expect(processDateBackWithHourMaybe('', locale), '');
      expect(processDateBackWithHourMaybe('   ', locale), '');
    });

    test('an unparseable field yields an empty string instead of throwing', () {
      expect(processDateBackWithHourMaybe('not a date', locale), '');
    });

    test('a date with a time still parses', () {
      final parsed = processDateBackWithHourMaybe('12/31/2026 18:30', locale);
      expect(parsed, startsWith('2026-12-31T18:30'));
    });

    test('a date without a time still parses through the fallback', () {
      final parsed = processDateBackWithHourMaybe('12/31/2026', locale);
      expect(parsed, startsWith('2026-12-31'));
    });
  });

  group('processDateBack', () {
    test('a locale date still becomes an ISO day', () {
      expect(processDateBack('12/31/2026', locale), startsWith('2026-12-31'));
    });
  });
}
