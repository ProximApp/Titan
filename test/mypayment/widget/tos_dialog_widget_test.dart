import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/mypayment/ui/pages/main_page/tos_dialog.dart';

import '../../shared/app_scaffold.dart';

/// `TOSDialogBox`'s accept button, which has two shapes: with a decline
/// handler (the payment page always passes one) it signs and lets the page
/// close itself; without one, it closes its own route first.
///
/// The page never leaves `onNo` out, so the second shape is only reachable by
/// mounting the dialog the way another caller would — which is what this file
/// does. It is also the only place the dialog is built on its own: everywhere
/// else it is reached through the page's terms gate.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Opens the dialog over a blank page and returns the accept counter, so a
  /// test can tell "the handler ran" from "the dialog merely closed".
  Future<List<int>> openDialog(
    WidgetTester tester, {
    bool withDecline = false,
  }) async {
    final accepted = <int>[];
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => TOSDialogBox(
                title: 'New Terms of Service',
                descriptions: 'Some terms',
                onYes: () async => accepted.add(1),
                onNo: withDecline ? () {} : null,
              ),
            ),
            child: const Text('Open the terms'),
          ),
        ),
      ),
      container,
      locale: const Locale('en', 'US'),
    );
    await settle(tester, frames: 4);

    await tester.tap(find.text('Open the terms'));
    await settle(tester, frames: 10);
    expect(find.text('New Terms of Service'), findsOneWidget);
    if (withDecline) {
      expect(find.text('Decline'), findsOneWidget);
    }
    return accepted;
  }

  testWidgets('accepting without a decline handler pops and then signs', (
    tester,
  ) async {
    final accepted = await openDialog(tester);

    await tester.tap(find.text('Accept'));
    await settle(tester, frames: 10);

    // The dialog closed itself (there was no page to do it for it) and the
    // signature still ran afterwards.
    expect(find.text('New Terms of Service'), findsNothing);
    expect(accepted, hasLength(1));
  });

  testWidgets('declining without a handler also closes the dialog', (
    tester,
  ) async {
    final accepted = await openDialog(tester);

    await tester.tap(find.text('Decline'));
    await settle(tester, frames: 10);

    expect(find.text('New Terms of Service'), findsNothing);
    expect(accepted, isEmpty);
  });

  testWidgets('accepting with a decline handler leaves the route to it', (
    tester,
  ) async {
    final accepted = await openDialog(tester, withDecline: true);

    await tester.tap(find.text('Accept'));
    await settle(tester, frames: 10);

    // The handler's owner closes the dialog, so it must still be up here.
    expect(find.text('New Terms of Service'), findsOneWidget);
    expect(accepted, hasLength(1));

    // Decline has the same contract in that shape: the handler is called and
    // the pop belongs to whoever passed it, so the dialog stays put.
    await tester.tap(find.text('Decline'));
    await settle(tester, frames: 10);
    expect(find.text('New Terms of Service'), findsOneWidget);
    expect(accepted, hasLength(1));
  });
}
