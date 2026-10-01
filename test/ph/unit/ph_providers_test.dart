import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/providers/ph_list_provider.dart';
import 'package:titan/ph/providers/ph_provider.dart';
import 'package:titan/ph/providers/selected_year_list_provider.dart';
import 'package:titan/ph/providers/year_list_provider.dart';
import 'package:titan/ph/tools/functions.dart';

/// Fake of the ph list so the year derivation runs without a repository.
class FakePhListNotifier extends PhListNotifier {
  FakePhListNotifier(this.papers, {this.loading = false});

  final List<PaperComplete> papers;
  final bool loading;

  @override
  AsyncValue<List<PaperComplete>> build() =>
      loading ? const AsyncValue.loading() : AsyncValue.data(papers);
}

PaperComplete paper(String id, String name, int year) => PaperComplete.empty()
    .copyWith(id: id, name: name, releaseDate: DateTime(year, 3, 7));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // DateFormat needs the locale tables initialized in tests.
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ph tools functions', () {
    test('phFormatDate formats in the requested locale', () {
      expect(phFormatDate(DateTime(2026, 3, 7), 'en'), 'March 7, 2026');
      expect(phFormatDate(DateTime(2026, 3, 7), 'fr'), '7 mars 2026');
    });

    test('phFormatDateEntry formats with the short month style', () {
      expect(phFormatDateEntry(DateTime(2026, 12, 31), 'en'), 'Dec 31, 2026');
    });

    test('shortenText keeps short text and truncates with ellipsis', () {
      expect(shortenText('Short', 10), 'Short');
      expect(shortenText('A very long text indeed', 10), 'A very ...');
    });
  });

  group('YearListNotifier', () {
    test('derives distinct years from the ph list', () {
      final container = ProviderContainer(
        overrides: [
          phListProvider.overrideWith(
            () => FakePhListNotifier([
              paper('p1', 'PH 1', 2026),
              paper('p2', 'PH 2', 2026),
              paper('p3', 'PH 3', 2025),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(yearListProvider), unorderedEquals([2025, 2026]));
    });

    test('addYear appends without mutating the previous state list', () {
      final container = ProviderContainer(
        overrides: [phListProvider.overrideWith(() => FakePhListNotifier([]))],
      );
      addTearDown(container.dispose);
      final notifier = container.read(yearListProvider.notifier);
      notifier.state = [2025];

      final previous = notifier.state;
      notifier.addYear(2026);

      expect(notifier.state, [2025, 2026]);
      // The previous value must be untouched: in-place mutation breaks
      // Riverpod's change listeners.
      expect(previous, [2025]);
      expect(identical(previous, notifier.state), isFalse);
    });

    test('returns an empty year list while the ph list is loading', () {
      final container = ProviderContainer(
        overrides: [
          phListProvider.overrideWith(
            () => FakePhListNotifier(const [], loading: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(yearListProvider), isEmpty);
    });
  });

  group('SelectedYearListNotifier', () {
    test('addYear then removeYear around a year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(selectedYearListProvider.notifier);
      // The default selection is the current year; pick another one.
      const year = 1999;

      notifier.addYear(year);
      expect(notifier.state, contains(year));
      notifier.removeYear(year);
      expect(notifier.state, isNot(contains(year)));
    });
  });

  group('PhNotifier', () {
    test('setPh replaces the selected paper', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final paper = PaperComplete.empty().copyWith(
        id: 'p1',
        name: 'PH Spring',
        releaseDate: DateTime(2026, 4, 1),
      );

      container.read(phProvider.notifier).setPh(paper);

      expect(container.read(phProvider).id, 'p1');
      expect(container.read(phProvider).name, 'PH Spring');
    });
  });
}
