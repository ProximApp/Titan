import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';

/// Drives every dismissal path of [CustomDialogBox]: absorb taps on the
/// card, the black backdrop pop (and its `onBarrierTap` override), the No
/// button with and without `onNo`, and the Yes button's two arms.
Widget _opener({
  required Future<void> Function() onYes,
  Function()? onNo,
  VoidCallback? onBarrierTap,
}) => Builder(
  builder: (context) => Center(
    child: ElevatedButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => CustomDialogBox(
          title: 'Delete?',
          descriptions: 'This cannot be undone.',
          yesText: 'YES',
          noText: 'NO',
          onYes: onYes,
          onNo: onNo,
          onBarrierTap: onBarrierTap,
        ),
      ),
      child: const Text('open'),
    ),
  ),
);

void main() {
  testWidgets('backdrop tap and the default No/Yes arms dismiss the dialog', (
    tester,
  ) async {
    var yesCalls = 0;
    await pumpWidgetAt(tester, _opener(onYes: () async => yesCalls++));

    // A tap on the card itself is absorbed by the inner detector.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete?'));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsOneWidget);

    // A tap on the black backdrop pops through the outer detector.
    await tester.tapAt(const Offset(10, 620));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsNothing);

    // No without onNo: pop.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NO'));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsNothing);

    // Yes without onNo: pop, then run onYes.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsNothing);
    expect(yesCalls, 1);
  });

  testWidgets(
    'onBarrierTap replaces the backdrop pop instead of adding to it',
    (tester) async {
      var barrierCalls = 0;
      await pumpWidgetAt(
        tester,
        _opener(onYes: () async {}, onBarrierTap: () => barrierCalls++),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 620));
      await tester.pumpAndSettle();

      expect(barrierCalls, 1);
      // The route is still there: the call site owns what a backdrop tap means,
      // which is the whole point of the override for an inline box.
      expect(find.text('Delete?'), findsOneWidget);

      // The card still swallows its own taps rather than counting them.
      await tester.tap(find.text('Delete?'));
      await tester.pumpAndSettle();
      expect(barrierCalls, 1);
      expect(find.text('Delete?'), findsOneWidget);
    },
  );

  testWidgets('with onNo provided, No calls back and Yes never pops', (
    tester,
  ) async {
    var noCalls = 0;
    var yesCalls = 0;
    await pumpWidgetAt(
      tester,
      _opener(onNo: () => noCalls++, onYes: () async => yesCalls++),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('NO'));
    await tester.pumpAndSettle();
    expect(noCalls, 1);
    expect(find.text('Delete?'), findsOneWidget);

    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    expect(yesCalls, 1);
    expect(find.text('Delete?'), findsOneWidget);
  });
}
