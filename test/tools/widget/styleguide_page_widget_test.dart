import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/styleguide/styleguide_page.dart';

import '../../shared/app_scaffold.dart';

/// The styleguide is one long scroll of every app component demo (navbar,
/// buttons, entries, chips, list items, toggles, search, modals…). A single
/// tall-surface mount executes the whole static tree; the extra drag scrolls
/// the tail into the paint region so the lower sections render end to end.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('mounts and scrolls through every demo section', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      const StyleGuidePage(),
      container: container,
      surface: const ui.Size(600, 2400),
      appFonts: true,
    );

    expect(find.text('Components'), findsOneWidget);
    expect(find.text('1. Floating Navigation Bar'), findsOneWidget);
    expect(find.text('2. Buttons'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1600),
    );
    await settle(tester, frames: 4);

    // TopBar's brand renders as AutoSizeText (README convention 5).
    expect(
      find.byWidgetPredicate((w) => w is AutoSizeText && w.data == 'myemapp'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
