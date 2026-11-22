import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/widgets/admin_button.dart';
import 'package:titan/tools/ui/widgets/styled_search_bar.dart';
import 'package:titan/tools/ui/widgets/text_entry.dart';
import 'package:titan/tools/ui/layouts/item_chip.dart';

import '../../shared/app_scaffold.dart';

/// Mount coverage for the four standalone tools widgets: [StyledSearchBar],
/// [AdminButton], the widgets [TextEntry] and [ItemChip]. Each is driven the
/// way a page would use it — typing into the field, tapping the button, and
/// running the validator through a real [Form].
void main() {
  group('StyledSearchBar', () {
    testWidgets('typing feeds the text back through onChanged', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      String? heard;

      await pumpWidgetAt(
        tester,
        StyledSearchBar(
          label: 'Look up',
          onChanged: (value) async => heard = value,
        ),
        container: container,
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Look up'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'abcd');
      await tester.pump();
      expect(heard, 'abcd');
    });

    testWidgets('a suffix tap reaches onSuffixIconTap with the field state', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      FocusNode? heardNode;
      TextEditingController? heardController;

      await pumpWidgetAt(
        tester,
        StyledSearchBar(
          label: 'Filter',
          editingController: controller,
          padding: const EdgeInsets.all(8),
          color: Colors.blue,
          onSuffixIconTap: (node, ctrler) {
            heardNode = node;
            heardController = ctrler;
          },
        ),
        container: container,
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(heardNode, isNotNull);
      expect(heardController, same(controller));
    });
  });

  group('AdminButton', () {
    testWidgets('a gradient button taps through to onTap', (tester) async {
      var taps = 0;
      await pumpWidgetAt(
        tester,
        AdminButton(
          onTap: () => taps++,
          colors: const [Colors.red, Colors.blue],
          text: 'Moderate',
        ),
      );

      expect(find.text('Moderate'), findsOneWidget);
      await tester.tap(find.text('Moderate'));
      expect(taps, 1);
    });

    testWidgets('the flat variant still builds and taps', (tester) async {
      var taps = 0;
      await pumpWidgetAt(tester, AdminButton(onTap: () => taps++));

      await tester.tap(find.byType(AdminButton));
      expect(taps, 1);
    });
  });

  group('TextEntry validation', () {
    Future<FormState> pumpForm(WidgetTester tester, List<Widget> fields) async {
      await pumpWidgetAt(tester, Form(child: ListView(children: fields)));
      return tester.state<FormState>(find.byType(Form));
    }

    testWidgets('an empty required field fails, an optional one passes', (
      tester,
    ) async {
      final name = TextEditingController();
      final note = TextEditingController();
      addTearDown(name.dispose);
      addTearDown(note.dispose);

      final form = await pumpForm(tester, [
        TextEntry(label: 'Name', controller: name),
        TextEntry(label: 'Note', controller: note, canBeEmpty: true),
      ]);

      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('suffix and prefix decorations build beside the field', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      final form = await pumpForm(tester, [
        TextEntry(label: 'Amount', controller: controller, suffix: 'ms'),
        TextEntry(label: 'Price', controller: controller, prefix: 'EUR'),
      ]);

      expect(find.text('ms'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(form.validate(), isFalse);
    });

    testWidgets('isInt refuses non-numbers and accepts a plain integer', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final form = await pumpForm(tester, [
        TextEntry(label: 'Count', controller: controller, isInt: true),
      ]);

      await tester.enterText(find.byType(TextFormField), 'twelve');
      expect(form.validate(), isFalse);

      await tester.enterText(find.byType(TextFormField), '5');
      expect(form.validate(), isTrue);
    });

    testWidgets('isDouble parses a comma decimal and rejects junk', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final form = await pumpForm(tester, [
        TextEntry(label: 'Size', controller: controller, isDouble: true),
      ]);

      await tester.enterText(find.byType(TextFormField), 'not-a-number');
      expect(form.validate(), isFalse);

      await tester.enterText(find.byType(TextFormField), '1,5');
      expect(form.validate(), isTrue);
    });

    testWidgets('a custom validator still gets the last word', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final form = await pumpForm(tester, [
        TextEntry(
          label: 'Code',
          controller: controller,
          validator: (value) => value == 'ok' ? null : 'nope',
        ),
      ]);

      await tester.enterText(find.byType(TextFormField), 'wrong');
      expect(form.validate(), isFalse);

      await tester.enterText(find.byType(TextFormField), 'ok');
      expect(form.validate(), isTrue);
    });
  });

  group('ItemChip', () {
    testWidgets('tap and long-press reach their callbacks', (tester) async {
      var taps = 0;
      var longPresses = 0;

      await pumpWidgetAt(
        tester,
        Row(
          children: [
            ItemChip(
              selected: true,
              onTap: () => taps++,
              onLongPress: () => longPresses++,
              child: const Text('chip'),
            ),
            const ItemChip(child: Text('plain')),
          ],
        ),
      );

      await tester.tap(find.text('chip'));
      await tester.pump();
      expect(taps, 1);

      await tester.longPress(find.text('chip'));
      await tester.pump();
      expect(longPresses, 1);
    });

    testWidgets('the vertical variant spans the cross axis', (tester) async {
      await pumpWidgetAt(
        tester,
        Column(
          children: const [ItemChip(vertical: true, child: Text('stacked'))],
        ),
      );

      expect(find.text('stacked'), findsOneWidget);
      // Full cross-axis width: the `vertical` chip ignores the row inset and
      // spans the column.
      final box = tester.renderObject<RenderBox>(find.byType(ItemChip));
      expect(box.size.width, 360);
    });
  });
}
