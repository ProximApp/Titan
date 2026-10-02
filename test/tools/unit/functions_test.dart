import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:titan/tools/functions.dart';

/// Unit coverage for the pure date/string helpers in
/// `lib/tools/functions.dart` (its largest uncovered block). The config
/// getters that read dart-defines (`getAppFlavor`, `getTitanHost`,
/// `getTitanURL`, …) are exercised by every integration shell booting with
/// the real CI defines; the platform-dialog wrappers (`getOnlyDayDate`
/// and friends) need a routed context and are covered by the form
/// round-trips in the integration shells.
void main() {
  // The date helpers build DateFormat objects for explicit locales; the
  // integration shells get the symbols from MaterialApp's localization
  // delegates, a plain `flutter test` does not.
  setUpAll(initializeDateFormatting);

  group('version helpers', () {
    test('isVersionCompatible accepts equal and newer versions', () {
      expect(isVersionCompatible('1.2.3', '1.2.3'), isTrue);
      expect(isVersionCompatible('2.0.0', '1.9.9'), isTrue);
      expect(isVersionCompatible('1.3.0', '1.2.9'), isTrue);
      expect(isVersionCompatible('1.2.4', '1.2.3'), isTrue);
    });

    test('isVersionCompatible rejects older major/minor/patch', () {
      expect(isVersionCompatible('0.9.9', '1.0.0'), isFalse);
      expect(isVersionCompatible('1.1.9', '1.2.0'), isFalse);
      expect(isVersionCompatible('1.2.2', '1.2.3'), isFalse);
    });
  });

  group('csv parsing', () {
    test('parseCsvContent answers empty for empty content', () {
      expect(parseCsvContent(''), isEmpty);
    });

    test('parseCsvContent answers empty when no line has fields', () {
      expect(parseCsvContent('\n  \n\t\n'), isEmpty);
    });

    test('parseCsvContent detects the comma separator and dedupes', () {
      expect(
        parseCsvContent('a@b.fr, c@d.fr, a@b.fr'),
        unorderedEquals(['a@b.fr', 'c@d.fr']),
      );
    });

    test('parseCsvContent detects the semicolon separator', () {
      expect(
        parseCsvContent('a@b.fr;c@d.fr'),
        unorderedEquals(['a@b.fr', 'c@d.fr']),
      );
    });

    test('parseCsvContent detects the tab separator', () {
      expect(
        parseCsvContent('a@b.fr\tc@d.fr'),
        unorderedEquals(['a@b.fr', 'c@d.fr']),
      );
    });

    test('parseCsvContent detects the pipe separator', () {
      expect(
        parseCsvContent('a@b.fr|c@d.fr'),
        unorderedEquals(['a@b.fr', 'c@d.fr']),
      );
    });

    test('parseCsvContent keeps only valid email-looking fields', () {
      expect(
        parseCsvContent('not-an-email, real@site.io, also@bad'),
        unorderedEquals(['real@site.io']),
      );
    });

    test('parseCsvContent trims fields', () {
      expect(
        parseCsvContent('  a@b.fr  , c@d.fr '),
        unorderedEquals(['a@b.fr', 'c@d.fr']),
      );
    });
  });

  group('string casing', () {
    test('capitalize lowercases the tail', () {
      expect(capitalize(''), '');
      expect(capitalize('hELLO'), 'Hello');
      expect(capitalize('a'), 'A');
    });

    test('capitaliseAll splits on spaces, dashes and underscores', () {
      expect(capitaliseAll(''), '');
      expect(capitaliseAll('jean-luc picard'), 'Jean-Luc Picard');
      // Underscores are NOT a splitter (only the literal chars are kept).
      expect(capitaliseAll('my_secret-club'), 'My_Secret-Club');
    });
  });

  group('date conversions', () {
    test('isDateBefore parses and compares ISO strings', () {
      expect(isDateBefore('2026-01-01', '2026-01-02'), isTrue);
      expect(isDateBefore('2026-01-02', '2026-01-01'), isFalse);
    });

    test('processDatePrint renders dd/mm/yyyy with zero padding', () {
      expect(processDatePrint(''), '');
      expect(processDatePrint('2026-3-5'), '05/03/2026');
    });

    test('processDateBack round-trips a yMd string', () {
      expect(processDateBack('12/31/2100', 'en_US'), '2100-12-31');
      expect(processDateBack('31/12/2100', 'fr_FR'), '2100-12-31');
    });

    test('processDateBackWithHour keeps the time', () {
      // 20:30 renders as 8:30 PM in en_US and parses back to 08:30 on a
      // 24h clock.
      expect(
        processDateBackWithHour('12/31/2100 8:30 PM', 'en_US'),
        '2100-12-31T08:30:00.000',
      );
    });

    test('processDateBackWithHourMaybe falls back to date-only parsing', () {
      expect(
        processDateBackWithHourMaybe('12/31/2100 8:30 PM', 'en_US'),
        '2100-12-31T08:30:00.000',
      );
      expect(
        processDateBackWithHourMaybe('12/31/2100', 'en_US'),
        '2100-12-31T00:00:00.000',
      );
    });

    test('normalizedDate zeroes the time components', () {
      expect(
        normalizedDate(DateTime(2026, 5, 4, 13, 37, 12)),
        DateTime(2026, 5, 4),
      );
    });

    test('processDateToAPI produces a UTC ISO string', () {
      expect(
        processDateToAPI(DateTime(2026, 1, 2, 3, 4)),
        DateTime(2026, 1, 2, 3, 4).toUtc().toIso8601String(),
      );
    });

    test('processDateToAPIWithoutHour keeps the date part only', () {
      expect(
        processDateToAPIWithoutHour(DateTime(2026, 1, 2, 3, 4)),
        '2026-01-02',
      );
    });

    test('processDateFromAPI converts to local time', () {
      final local = processDateFromAPI('2026-01-02T03:04:00.000Z');
      expect(local.isUtc, isFalse);
      expect(local.toUtc(), DateTime.utc(2026, 1, 2, 3, 4));
    });

    test('processDateFromAPIWithoutHour parses date-only strings', () {
      expect(processDateFromAPIWithoutHour('2026-01-02'), DateTime(2026, 1, 2));
    });
  });

  group('display formatting', () {
    test('parseDate splits a DateTime into date and time parts', () {
      expect(parseDate(DateTime(2026, 1, 2, 3, 4)), ['02/01/2026', '03:04']);
    });

    test('formatDates renders a same-day range', () {
      final start = DateTime(2100, 12, 31, 10);
      final end = DateTime(2100, 12, 31, 12);
      expect(formatDates(start, end, false), 'Le 31/12/2100 de 10:00 à 12:00');
      expect(formatDates(start, end, true), 'Le 31/12/2100 toute la journée');
    });

    test('formatDates renders a multi-day range', () {
      expect(
        formatDates(
          DateTime(2100, 12, 30, 10),
          DateTime(2100, 12, 31, 12),
          false,
        ),
        'Du 30/12/2100 à 10:00 au 31/12/2100 à 12:00',
      );
    });

    test('formatRecurrenceRule renders a non-recurring same-day range', () {
      expect(
        formatRecurrenceRule(
          DateTime(2100, 12, 31, 10),
          DateTime(2100, 12, 31, 12),
          '',
          false,
          'en_US',
        ),
        'Le 31/12/2100 de 10:00 à 12:00',
      );
    });

    test('formatRecurrenceRule renders a non-recurring multi-day range', () {
      expect(
        formatRecurrenceRule(
          DateTime(2100, 12, 30, 10),
          DateTime(2100, 12, 31, 12),
          '',
          false,
          'en_US',
        ),
        'Du 30/12/2100 à 10:00 au 31/12/2100 à 12:00',
      );
    });

    test('formatRecurrenceRule renders a weekly recurrence', () {
      // Every Thursday until the end date, with hours. A recurring rule
      // never renders the leading date.
      expect(
        formatRecurrenceRule(
          DateTime(2026, 3, 5, 10),
          DateTime(2026, 3, 5, 12),
          'FREQ=WEEKLY;BYDAY=TH;UNTIL=20260402T000000Z',
          false,
          'en_US',
        ),
        'Tous les Jeudi de 10:00 à 12:00 jusqu\'au 4/2/2026',
      );
    });

    test('formatRecurrenceRule renders multiple weekdays', () {
      expect(
        formatRecurrenceRule(
          DateTime(2026, 3, 5, 10),
          DateTime(2026, 3, 5, 12),
          'FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20260402T000000Z',
          true,
          'en_US',
        ),
        'Tous les Lundi, Mercredi et Vendredi toute la journée '
        'jusqu\'au 4/2/2026',
      );
    });
  });

  group('hash and color helpers', () {
    test('generateColor maps a string to a stable opaque color', () {
      final a = generateColor('user-1');
      final b = generateColor('user-1');
      final c = generateColor('user-2');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.alpha, 255);
    });

    test('generateIntFromString is stable and order-sensitive', () {
      expect(generateIntFromString('ab'), generateIntFromString('ab'));
      expect(generateIntFromString('ab'), isNot(generateIntFromString('ba')));
    });

    test('combineDate merges a day and a time', () {
      expect(
        combineDate(DateTime(2026, 5, 4), DateTime(2100, 1, 1, 14, 30)),
        DateTime(2026, 5, 4, 14, 30),
      );
    });

    test('getMonth wraps around the year', () {
      // 0 is December (the array is rotated so m % 12 works for 1..12).
      expect(getMonth(0), 'Décembre');
      expect(getMonth(1), 'Janvier');
      expect(getMonth(12), 'Décembre');
      expect(getMonth(13), 'Janvier');
    });
  });

  group('email classifiers', () {
    // The legacy regexes target ec-lyon.fr addresses (see
    // lib/tools/constants.dart).
    test('isEmailInValid flags the legacy email regex', () {
      expect(isEmailInValid('jean@ecl25.ec-lyon.fr'), isTrue);
      expect(isEmailInValid('jean@master.ec-lyon.fr'), isTrue);
      expect(isEmailInValid('jean@other.fr'), isFalse);
    });

    test('isStudent matches student addresses', () {
      expect(isStudent('someone@etu.ec-lyon.fr'), isTrue);
      expect(isStudent('someone@etu-enise.ec-lyon.fr'), isTrue);
      expect(isStudent('someone@ec-lyon.fr'), isFalse);
    });

    test('isNotStaff inverts the legacy staff regex', () {
      expect(isNotStaff('someone@etu.ec-lyon.fr'), isTrue);
      expect(isNotStaff('someone@ec-lyon.fr'), isFalse);
    });
  });
}
