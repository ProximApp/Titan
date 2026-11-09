import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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

    test('the picker shape (yMMMd) becomes an ISO day too', () {
      // What getOnlyDayDate leaves in the controller after a tap; loan's
      // start date and booking's range both round-trip it through here.
      expect(processDateBack('Dec 31, 2026', locale), '2026-12-31');
    });

    test('a French picker date becomes an ISO day', () async {
      // intl needs the locale data loaded first — the app does this at
      // startup, so the test has to mirror it before the fr shape can parse.
      await initializeDateFormatting('fr');
      final pickerText = DateFormat.yMMMd('fr').format(DateTime(2026, 12, 31));

      expect(processDateBack(pickerText, 'fr'), '2026-12-31');
    });

    test('input in neither shape still throws', () {
      // No third fallback: this parser feeds model writes, and guessing a
      // date would persist a wrong one.
      expect(
        () => processDateBack('not a date', locale),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
