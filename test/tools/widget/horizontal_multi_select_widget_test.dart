import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/styleguide/horizontal_multi_select.dart';
import 'package:titan/tools/ui/styleguide/item_chip.dart';

/// The strip compares items either by identity or through the `isEqual`
/// callback a caller passes when its items are value objects that get rebuilt.
void main() {
  Widget strip({String? selected, bool withEquality = true}) => MaterialApp(
    home: Scaffold(
      body: HorizontalMultiSelect<String>(
        items: const ['a', 'b'],
        selectedItem: selected,
        isEqual: withEquality ? (a, b) => a == b : null,
        itemBuilder: (context, item, index, sel) => Text('$item:$sel'),
      ),
    ),
  );

  bool selectedOf(WidgetTester tester, int index) =>
      tester.widget<ItemChip>(find.byType(ItemChip).at(index)).selected;

  testWidgets('with nothing selected every chip is off', (tester) async {
    await tester.pumpWidget(strip());

    expect(selectedOf(tester, 0), isFalse);
    expect(selectedOf(tester, 1), isFalse);
  });

  testWidgets('the item the callback matches is the selected one', (
    tester,
  ) async {
    await tester.pumpWidget(strip(selected: 'b'));

    expect(selectedOf(tester, 0), isFalse);
    expect(selectedOf(tester, 1), isTrue);
  });

  testWidgets('without a callback the comparison falls back to equality', (
    tester,
  ) async {
    await tester.pumpWidget(strip(selected: 'b', withEquality: false));

    expect(selectedOf(tester, 0), isFalse);
    expect(selectedOf(tester, 1), isTrue);
  });

  testWidgets('a leading child is kept and the callbacks reach the item', (
    tester,
  ) async {
    final taps = <String>[];
    final longPresses = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HorizontalMultiSelect<String>(
            items: const ['a', 'b'],
            firstChild: const Text('lead'),
            onItemSelected: taps.add,
            onLongPress: longPresses.add,
            itemBuilder: (context, item, index, selected) => Text(item),
          ),
        ),
      ),
    );

    expect(find.text('lead'), findsOneWidget);
    expect(selectedOf(tester, 0), isFalse);

    await tester.tap(find.text('b'));
    await tester.pump();
    await tester.longPress(find.text('a'));
    await tester.pump();

    expect(taps, ['b']);
    expect(longPresses, ['a']);
  });
}
