import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:titan/tools/functions.dart';

/// The closest public boundary to `edit_ticket_event_page.dart`'s session
/// date-parse catch (line 743).
///
/// That catch only runs when the add-session modal hands `save`-time text that
/// matches neither pattern `processDateBackWithHourMaybe` accepts, which then
/// answers `''` and makes `DateTime.parse` throw. The row has no field to type
/// into, so the only writer is `getFullDate`:
///
///     dateController.text = DateFormat.yMd(locale).add_Hm().format(picked);
///
/// — the very pattern the reader parses. The first test pins that round-trip
/// for both shipped locales, which is why the catch cannot fire from a pick;
/// the second shows what it would take (a shape nothing in the modal writes),
/// and is as close to the line as a public call gets.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  test('a picked session date survives the trip out and back', () {
    final picked = DateTime(2026, 1, 10, 18, 30);

    for (final locale in ['en', 'fr']) {
      final text = DateFormat.yMd(locale).add_Hm().format(picked);
      expect(
        DateTime.parse(processDateBackWithHourMaybe(text, locale)),
        picked,
        reason: 'locale $locale writes "$text"',
      );
    }
  });

  test('the catch needs a shape the session row cannot hold', () {
    // Neither accepted pattern matches this, so the helper answers with the
    // empty string the page would hand to DateTime.parse: a SHAPE mismatch.
    expect(processDateBackWithHourMaybe('garbage', 'en'), '');
    expect(processDateBackWithHourMaybe('garbage', 'fr'), '');
    expect(() => DateTime.parse(''), throwsFormatException);

    // A wrong VALUE does not do it. intl rolls out-of-range fields over
    // instead of throwing, which this run observed: under en, yMd+Hm reads
    // `10/01/2026` as October 1, `25/01/2026 18:00` as 1 January 2028 and
    // `99/99/9999 99:99` as a year-10007 date. So the old dd/MM event rows
    // did not crash on a day past 12 — they silently sent another date, which
    // is what the `dateFormatter` fix removed. Nothing in the session modal
    // writes a shape at all: `getFullDate` formats with the pattern this
    // helper parses (first test).
    expect(
      processDateBackWithHourMaybe('25/01/2026 18:00', 'en'),
      DateTime(2028, 1, 1, 18).toIso8601String(),
    );
  });
}
