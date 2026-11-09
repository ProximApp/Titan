import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/seed-library/ui/components/delete_button.dart';

/// The delete button's two states: a live one runs its callback, and a
/// deactivated one renders the greyed gradient but swallows the tap, which is
/// what stops a plant from being deleted while another action is in flight.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required bool deactivated,
    required VoidCallback onDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DeleteButton(
              onDelete: onDelete,
              deactivated: deactivated,
              deletion: false,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a live delete button runs its callback', (tester) async {
    var taps = 0;
    await pumpButton(tester, deactivated: false, onDelete: () => taps++);

    await tester.tap(find.byType(DeleteButton));
    await tester.pump();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a deactivated delete button ignores taps', (tester) async {
    var taps = 0;
    await pumpButton(tester, deactivated: true, onDelete: () => taps++);

    await tester.tap(find.byType(DeleteButton));
    await tester.pump();

    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });
}
