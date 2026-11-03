import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/styleguide/text_entry.dart';

import '../../shared/app_scaffold.dart';

/// `TextEntry`'s build paths no other demo reaches: the non-empty `prefix`
/// adornment, and the `isInt` / `isDouble` validator arms — validation only
/// runs when a Form asks for it, which the styleguide's entry demos never do.
void main() {
  testWidgets(
    'the prefix renders and the numeric validators reject and accept',
    (tester) async {
      final intController = TextEditingController();
      final doubleController = TextEditingController();
      final codeController = TextEditingController();
      addTearDown(intController.dispose);
      addTearDown(doubleController.dispose);
      addTearDown(codeController.dispose);
      final formKey = GlobalKey<FormState>();

      await pumpWidgetAt(
        tester,
        Form(
          key: formKey,
          child: Column(
            children: [
              TextEntry(
                label: 'Amount',
                controller: intController,
                prefix: '€',
                isInt: true,
              ),
              TextEntry(
                label: 'Ratio',
                controller: doubleController,
                isDouble: true,
              ),
              TextEntry(
                label: 'Code',
                controller: codeController,
                validator: (value) => value == 'ok' ? null : 'Nope',
              ),
            ],
          ),
        ),
      );

      // The prefix adornment renders as its own Text next to the field.
      expect(find.text('€'), findsOneWidget);

      // All empty: the required message (canBeEmpty is false), no numeric
      // parsing yet — asserted after the frame the failed validate triggers.
      expect(formKey.currentState!.validate(), isFalse);
      await settle(tester, frames: 4);
      expect(find.text('No value'), findsNWidgets(3));

      // Non-numeric input trips each numeric arm.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        'abc',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Ratio'), 'x');
      expect(formKey.currentState!.validate(), isFalse);
      await settle(tester, frames: 4);
      expect(find.text('Invalid number'), findsNWidgets(2));

      // A plain int, a comma-decimal double (the decimal comma is the
      // isDouble arm's own replaceAll) and the custom-validated code pass.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '42',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ratio'),
        '3,5',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Code'), 'ok');
      expect(formKey.currentState!.validate(), isTrue);
      await settle(tester, frames: 4);

      // The caller-supplied validator gets the final word once the value is
      // present and numeric.
      await tester.enterText(find.widgetWithText(TextFormField, 'Code'), 'x');
      expect(formKey.currentState!.validate(), isFalse);
      await settle(tester, frames: 4);
      expect(find.text('Nope'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Code'), 'ok');
      expect(formKey.currentState!.validate(), isTrue);
      await settle(tester, frames: 4);
    },
  );
}
