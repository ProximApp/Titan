import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/widgets/vertical_clip_scroll.dart';

import '../../shared/app_scaffold.dart';

/// The clipper only cuts horizontally: painting it while scrolled exercises
/// `getClip`, and a rebuild swaps in a fresh clipper so `shouldReclip` runs.
Widget _tree(int rows) => VerticalClipScroll(
  child: Column(
    children: [
      for (var i = 0; i < rows; i++)
        SizedBox(height: 60, child: Text('row $i')),
    ],
  ),
);

void main() {
  testWidgets('paints the clip while scrolling and re-clips on rebuild', (
    tester,
  ) async {
    await pumpWidgetAt(tester, _tree(30));
    expect(find.text('row 0'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );

    // A new tree builds a new _VerticalOnlyClipper, so the render object
    // asks the new clipper whether to reclip.
    await pumpWidgetAt(tester, _tree(31));
    expect(find.text('row 30'), findsOneWidget);
  });
}
