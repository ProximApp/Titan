import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/edit_selected_items_provider.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/initial_date_provider.dart';
import 'package:titan/loan/providers/item_list_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';
import 'package:titan/loan/ui/pages/loan_group_page/start_date_entry.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';

import '../../shared/app_scaffold.dart';

/// Behaviour tests for `StartDateEntry` — the widget that seeds a loan's
/// start date and, from the selected items, its end date.
///
/// The card sweep only checks that it lays out; nothing drove the picker, so
/// the whole `onTap` body was uncovered. Driving it found a real defect: the
/// picker writes `DateFormat.yMMMd` ("Nov 15, 2026") but `processDateBack`
/// used to parse `DateFormat.yMd` only, so the end date was ALWAYS blank and
/// the initial-date write threw. These tests pin the fix from both sides.
class _FixedItemList extends ItemListNotifier {
  _FixedItemList(this.items);

  final List<Item> items;

  @override
  AsyncValue<List<Item>> build() => AsyncValue.data(items);
}

class _FixedSelection extends EditSelectedListProvider {
  _FixedSelection(this.selection);

  final List<int> selection;

  @override
  List<int> build() => selection;
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  final items = [
    Item.empty().copyWith(
      id: 'i-1',
      name: 'Tente',
      suggestedLendingDuration: 3,
    ),
    Item.empty().copyWith(
      id: 'i-2',
      name: 'Sac de couchage',
      suggestedLendingDuration: 7,
    ),
  ];

  ProviderContainer containerWith(List<int> selection) {
    final container = ProviderContainer(
      overrides: [
        itemListProvider.overrideWith(() => _FixedItemList(items)),
        editSelectedListProvider.overrideWith(() => _FixedSelection(selection)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Opens the widget's date picker and picks the 15th of the shown month.
  /// The picker opens on `now` (start is empty), so the 15th always exists.
  Future<DateTime> pickFifteenth(WidgetTester tester) async {
    await tester.tap(find.byType(DateEntry));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    return DateTime(now.year, now.month, 15);
  }

  testWidgets('picking a date sets the start and derives the end date', (
    tester,
  ) async {
    // One of the two items is selected, so the end date is the start plus the
    // shortest suggested lending duration (3 days).
    final container = containerWith([1, 0]);
    await scaffold.pumpWidgetApp(
      tester,
      const Scaffold(body: StartDateEntry()),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    final picked = await pickFifteenth(tester);

    final start = container.read(startProvider);
    // The picker's own yMMMd shape, which is what the fix makes parseable.
    expect(start, 'Nov 15, ${picked.year}');

    // Regression pin: this stayed empty for every locale before the parse fix.
    final end = container.read(endProvider);
    expect(end, isNotEmpty);
    expect(end, contains('${picked.add(const Duration(days: 3)).day}'));

    // The end-date entry reads its initial date from here, at midnight.
    final initial = container.read(initialDateProvider);
    expect(initial.year, picked.year);
    expect(initial.month, picked.month);
    expect(initial.day, picked.day);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty selection clears the end date instead of throwing', (
    tester,
  ) async {
    // The reduce(min) that derives the end date threw on an empty selection;
    // the widget's branch must leave the end entry blank — and still update
    // the initial date, which is the second half of the parse fix.
    final container = containerWith([0, 0]);
    await scaffold.pumpWidgetApp(
      tester,
      const Scaffold(body: StartDateEntry()),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    final picked = await pickFifteenth(tester);

    expect(container.read(startProvider), isNotEmpty);
    expect(container.read(endProvider), isEmpty);
    expect(container.read(initialDateProvider).day, picked.day);
    expect(tester.takeException(), isNull);
  });
}
