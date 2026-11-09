import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/styleguide/item_chip.dart';

import '../../shared/app_scaffold.dart';

/// The styleguide's `ItemChip` is the horizontal-or-vertical pill its demo
/// strips are built from. Its one branching decision is the margin: a row of
/// chips keeps the gap on the horizontal axis, a column keeps it on the
/// vertical one — every strip in the page scrolls horizontally, so the column
/// arm is driven here on its own.
void main() {
  testWidgets('the margin follows the declared scroll direction', (
    tester,
  ) async {
    await pumpWidgetAt(
      tester,
      const Column(
        children: [
          ItemChip(child: Text('row')),
          ItemChip(scrollDirection: Axis.vertical, child: Text('column')),
        ],
      ),
    );

    Container chipOf(String label) => tester.widget<Container>(
      find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(ItemChip),
        ),
        matching: find.byType(Container),
      ),
    );

    expect(chipOf('row').margin, const EdgeInsets.symmetric(horizontal: 5.0));
    expect(chipOf('column').margin, const EdgeInsets.symmetric(vertical: 5.0));
  });
}
