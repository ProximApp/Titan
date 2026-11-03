import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/layouts/horizontal_list_view.dart';

/// `HorizontalListView.builder` pads its item count with spacers and optional
/// leading/trailing widgets, so the index arithmetic is easy to get off by one:
/// an off-by-one shows the first item twice or drops the last one.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(height: 100, child: child)),
  );

  testWidgets('no decorations still shows every item in order', (tester) async {
    await tester.pumpWidget(
      wrap(
        HorizontalListView.builder(
          height: 100,
          items: const ['a', 'b', 'c'],
          itemBuilder: (context, item, i) => Text('$i:$item'),
        ),
      ),
    );

    expect(find.text('0:a'), findsOneWidget);
    expect(find.text('1:b'), findsOneWidget);
    expect(find.text('2:c'), findsOneWidget);
  });

  testWidgets('a first child leads the list without shifting the indices', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        HorizontalListView.builder(
          height: 100,
          items: const ['a', 'b'],
          firstChild: const Text('FIRST'),
          itemBuilder: (context, item, i) => Text('$i:$item'),
        ),
      ),
    );

    expect(find.text('FIRST'), findsOneWidget);
    expect(find.text('0:a'), findsOneWidget);
    expect(find.text('1:b'), findsOneWidget);
  });

  testWidgets('a last child closes the list after the final item', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        HorizontalListView.builder(
          height: 100,
          items: const ['a', 'b'],
          lastChild: const Text('LAST'),
          itemBuilder: (context, item, i) => Text('$i:$item'),
        ),
      ),
    );

    expect(find.text('0:a'), findsOneWidget);
    expect(find.text('1:b'), findsOneWidget);
    expect(find.text('LAST'), findsOneWidget);
  });

  testWidgets('both decorations keep the items intact between them', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        HorizontalListView.builder(
          height: 100,
          items: const ['a', 'b', 'c'],
          firstChild: const Text('FIRST'),
          lastChild: const Text('LAST'),
          itemBuilder: (context, item, i) => Text('$i:$item'),
        ),
      ),
    );

    for (final label in ['FIRST', '0:a', '1:b', '2:c', 'LAST']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a shorter length stops the builder early', (tester) async {
    await tester.pumpWidget(
      wrap(
        HorizontalListView.builder(
          height: 100,
          items: const ['a', 'b', 'c'],
          length: 2,
          itemBuilder: (context, item, i) => Text('$i:$item'),
        ),
      ),
    );

    expect(find.text('0:a'), findsOneWidget);
    expect(find.text('1:b'), findsOneWidget);
    expect(find.text('2:c'), findsNothing);
  });
}
