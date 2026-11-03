import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/builders/enums_cleaner.dart';

enum Sample { first, second, swaggerGeneratedUnknown }

/// Every dropdown built from a swagger enum feeds it through this filter: the
/// generator appends a `swaggerGeneratedUnknown` member that must never reach
/// a user-facing list, while the order of the real values is preserved.
void main() {
  test('drops the generated unknown member', () {
    expect(getEnumValues(Sample.values), [Sample.first, Sample.second]);
  });

  test('keeps a list that has nothing to drop', () {
    expect(getEnumValues([Sample.second, Sample.first]), [
      Sample.second,
      Sample.first,
    ]);
  });

  test('an empty list stays empty', () {
    expect(getEnumValues(<Sample>[]), isEmpty);
  });
}
