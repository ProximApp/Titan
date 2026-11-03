import 'package:flutter_test/flutter_test.dart';
import 'package:titan/cinema/tools/functions.dart';

/// `parseDuration` is fed straight from a text field: a blank or malformed
/// duration used to reach `int.parse` and throw a `FormatException` on save,
/// which reads to the user as a button that does nothing.
void main() {
  group('parseDuration', () {
    test('a blank field yields zero minutes instead of throwing', () {
      expect(parseDuration(''), 0);
      expect(parseDuration('   '), 0);
    });

    test('a malformed field yields zero minutes instead of throwing', () {
      expect(parseDuration('abc'), 0);
      expect(parseDuration('1h30'), 0);
      expect(parseDuration(':'), 0);
    });

    test('a valid hours:minutes field still converts', () {
      expect(parseDuration('1:45'), 105);
      expect(parseDuration('0:30'), 30);
      expect(parseDuration('2:00'), 120);
    });

    test('a missing minutes part is treated as zero', () {
      expect(parseDuration('2'), 120);
    });
  });
}
