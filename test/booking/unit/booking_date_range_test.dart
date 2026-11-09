import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/tools/functions.dart';

/// The booking form compares its two date fields on save. Empty fields used
/// to reach `processDateBack`'s `DateFormat.parse` — a `FormatException`
/// from an `onTap`, i.e. a Save button that silently does nothing.
void main() {
  const locale = 'en_US';

  group('hasInvalidBookingRange', () {
    test('a blank field is invalid before any parsing happens', () {
      expect(hasInvalidBookingRange('', '12/31/2026 10:00', locale), isTrue);
      expect(hasInvalidBookingRange('12/31/2026 10:00', ' ', locale), isTrue);
      expect(hasInvalidBookingRange('', '', locale), isTrue);
    });

    test('a time-only field is not a date and is left to the other guards', () {
      expect(hasInvalidBookingRange('10:00', '12:00', locale), isFalse);
    });

    test('an ordered range is valid', () {
      expect(
        hasInvalidBookingRange('12/30/2026 10:00', '12/31/2026 10:00', locale),
        isFalse,
      );
    });

    test('a reversed range is invalid', () {
      expect(
        hasInvalidBookingRange('12/31/2026 10:00', '12/30/2026 10:00', locale),
        isTrue,
      );
    });

    test('an unparseable field is invalid instead of throwing', () {
      expect(
        hasInvalidBookingRange('oops/1/2026', '12/31/2026', locale),
        isTrue,
      );
    });
  });
}
