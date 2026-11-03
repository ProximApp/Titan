import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';

import '../loan_fixtures.dart';

/// `setEndFromSelected` recovers the END date from the shortest suggested
/// lending duration of the selection. It parses the START field, which is a
/// free-form string, so an unparsable start must be a no-op rather than a
/// crash on the way into `DateTime.add`.
void main() {
  late ProviderContainer container;
  late EndNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(endProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('an unparsable start leaves the end untouched', () {
    notifier.setEnd('1/18/2026');

    notifier.setEndFromSelected('not-a-date', [itemFixture()], 'en_US');

    expect(container.read(endProvider), '1/18/2026');
  });

  test('an empty start is ignored before parsing', () {
    notifier.setEnd('1/18/2026');

    notifier.setEndFromSelected('', [itemFixture()], 'en_US');

    expect(container.read(endProvider), '1/18/2026');
  });

  test('an empty selection clears the end instead of reducing nothing', () {
    notifier.setEnd('1/18/2026');

    notifier.setEndFromSelected('1/15/2026', const [], 'en_US');

    expect(container.read(endProvider), '');
  });

  test('the shortest suggested duration wins', () {
    container.read(startProvider.notifier).setStart('1/15/2026');

    notifier.setEndFromSelected('1/15/2026', [
      itemFixture(id: 'i-1', suggestedLendingDuration: 7),
      itemFixture(id: 'i-2', suggestedLendingDuration: 3),
    ], 'en_US');

    expect(container.read(endProvider), '1/18/2026');
  });
}
