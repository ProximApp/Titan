import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/confirm_modal.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the shared `ConfirmModal`: it only ever
/// renders inside `showCustomBottomModal`, so a launcher button opens the
/// real route and the two action buttons are driven through it.
class _Launcher extends ConsumerWidget {
  const _Launcher(this.modal);

  final Widget modal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ElevatedButton(
        onPressed: () =>
            showCustomBottomModal(context: context, ref: ref, modal: modal),
        child: const Text('open modal'),
      ),
    );
  }
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Bounded pumps: the sheet and the navbar's modal animation must settle
  /// without an infinite-spinner hang.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> open(WidgetTester tester, Widget modal) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(tester, _Launcher(modal), container);
    await tester.tap(find.text('open modal'));
    await pumpFrames(tester);
  }

  testWidgets('the main modal confirms through its onYes', (tester) async {
    var yes = 0;
    var no = 0;
    await open(
      tester,
      ConfirmModal(
        title: 'Archive the year',
        description: 'Everything older than a year is archived.',
        onYes: () => yes++,
        onNo: () => no++,
      ),
    );

    expect(find.text('Archive the year'), findsOneWidget);
    expect(find.textContaining('archived'), findsWidgets);

    await tester.tap(find.text('Confirm'));
    await pumpFrames(tester);

    expect(yes, 1);
    expect(no, 0);
    expect(find.text('Archive the year'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the danger modal cancels through its onNo and honors custom '
      'labels', (tester) async {
    var yes = 0;
    var no = 0;
    await open(
      tester,
      ConfirmModal.danger(
        title: 'Delete the store',
        description: 'This cannot be undone.',
        yesText: 'Yes, delete',
        noText: 'Keep it',
        onYes: () => yes++,
        onNo: () => no++,
      ),
    );

    expect(find.text('Yes, delete'), findsOneWidget);
    expect(find.text('Keep it'), findsOneWidget);

    await tester.tap(find.text('Keep it'));
    await pumpFrames(tester);
    expect(no, 1);
    expect(yes, 0);
    expect(find.text('Delete the store'), findsNothing);

    await open(
      tester,
      ConfirmModal.danger(
        title: 'Delete the store',
        description: 'This cannot be undone.',
        yesText: 'Yes, delete',
        noText: 'Keep it',
        onYes: () => yes++,
        onNo: () => no++,
      ),
    );
    await tester.tap(find.text('Yes, delete'));
    await pumpFrames(tester);
    expect(yes, 1);
    expect(no, 1);
    expect(tester.takeException(), isNull);
  });
}
