import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/horizontal_multi_select.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/styleguide/item_chip.dart';
import 'package:titan/tools/ui/styleguide/searchbar.dart';
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

  Future<void> mountPage(WidgetTester tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await pumpWidgetAt(
      tester,
      const StyleGuidePage(),
      container: container,
      surface: const ui.Size(600, 2400),
      appFonts: true,
    );
  }

  /// Snackbars carry their own Timer; let it fire so the test does not end
  /// with a pending timer.
  Future<void> drainSnackbars(WidgetTester tester) async {
    await settle(tester, frames: 2);
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('both search bars answer their callbacks and the filter '
      'dialog offers every option', (tester) async {
    await mountPage(tester);

    // The first bar reports while typing and toasts its filter tap.
    final firstBar = find.byType(CustomSearchBar).at(0);
    await tester.enterText(
      find.descendant(of: firstBar, matching: find.byType(TextField)),
      'fleurs',
    );
    await drainSnackbars(tester);
    await tester.tap(
      find.descendant(of: firstBar, matching: find.byType(IconButton)).first,
    );
    await drainSnackbars(tester);

    // The second bar opens the filter dialog; every option pops with its
    // own snackbar.
    final secondBar = find.byType(CustomSearchBar).at(1);
    Finder filterButton() =>
        find.descendant(of: secondBar, matching: find.byType(IconButton)).first;
    for (final option in ['Name', 'Role', 'Age']) {
      await tester.tap(filterButton());
      await settle(tester, frames: 4);
      expect(find.text('Filter Options'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(option),
        ),
      );
      await drainSnackbars(tester);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the three modal demos open, act through their buttons and '
      'close again', (tester) async {
    await mountPage(tester);

    // Plain bottom modal.
    await tester.tap(find.text('Show Bottom Modal'));
    await settle(tester, frames: 6);
    expect(find.text('Modal Content Area'), findsOneWidget);
    await tester.tap(find.text('Close Modal'));
    await settle(tester, frames: 6);

    // Danger modal: both action buttons pop it.
    await tester.tap(find.text('Show Danger Modal'));
    await settle(tester, frames: 6);
    expect(find.text('Danger Content Area'), findsOneWidget);
    await tester.tap(find.text('Delete Permanently'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Show Danger Modal'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Cancel').last);
    await settle(tester, frames: 6);

    // Member management: the Add item toasts, the member row opens the
    // nested details modal whose role buttons toast through the pop.
    await tester.tap(find.text('Show Member Management Modal'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Add member'));
    await drainSnackbars(tester);
    await tester.tap(find.text('Show Member Management Modal'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Corpo'));
    await settle(tester, frames: 4);
    await tester.tap(find.text('Biero'));
    await settle(tester, frames: 4);
    await tester.tap(find.text('Zoto - Prez'));
    await settle(tester, frames: 6);
    expect(find.text('Role: Zoto - Prez'), findsOneWidget);
    await tester.tap(find.text('Modify Role'));
    await drainSnackbars(tester);
    await tester.tap(find.text('Show Member Management Modal'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Zoto - Prez'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Remove Role'));
    await drainSnackbars(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the multi-select strips toggle selection and the color '
      'picker adds', (tester) async {
    await mountPage(tester);

    await tester.tap(find.text('Apple'));
    await settle(tester, frames: 4);
    expect(
      find.descendant(
        of: find.byType(HorizontalMultiSelect<String>),
        matching: find.text('Apple'),
      ),
      findsOneWidget,
    );

    // The color strip's leading plus chip toasts "Add new color".
    await tester.tap(
      find
          .descendant(
            of: find.byType(HorizontalMultiSelect<Color>),
            matching: find.byType(HeroIcon),
          )
          .first,
    );
    await drainSnackbars(tester);

    await tester.tap(find.text('John'));
    await settle(tester, frames: 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the member-management modal search bar answers its '
      'callbacks', (tester) async {
    await mountPage(tester);

    await tester.ensureVisible(find.text('Show Member Management Modal'));
    await settle(tester, frames: 4);
    await tester.tap(find.text('Show Member Management Modal'));
    await settle(tester, frames: 6);
    expect(find.text('Member Management'), findsOneWidget);

    // The modal's bar lives in the overlay: the LAST CustomSearchBar in the
    // tree, above the page's own two in section 4.
    final modalBar = find.byType(CustomSearchBar).last;
    expect(
      find.descendant(of: modalBar, matching: find.text('Search members...')),
      findsOneWidget,
    );

    // Typing fires this demo's empty-bodied onSearch callback, and the
    // clear button that appears with the text works.
    final field = find.descendant(
      of: modalBar,
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'ada');
    await settle(tester, frames: 4);
    expect(tester.widget<TextField>(field).controller!.text, 'ada');

    // The filter icon fires onFilter.
    final filterIcon = find
        .descendant(
          of: modalBar,
          matching: find.byWidgetPredicate((w) => w is GestureDetector),
        )
        .last;
    await tester.tap(filterIcon);
    await settle(tester, frames: 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the color picker chip reports its selection', (tester) async {
    await mountPage(tester);

    final colorStrip = find.byType(HorizontalMultiSelect<Color>);
    final chips = find.descendant(
      of: colorStrip,
      matching: find.byType(ItemChip),
    );
    // Index 0 is the leading + chip; the first color chip is red — its
    // selection runs the demo's color-name ternary and toasts it.
    expect(chips, findsNWidgets(7));
    await tester.ensureVisible(chips.at(1));
    await settle(tester, frames: 4);
    await tester.tap(chips.at(1));
    await settle(tester, frames: 6);

    expect(find.text('Selected: Red'), findsOneWidget);
    // Full drain with tail frames: the snackbar's exit animation needs
    // frames AFTER the time jump, or the next selection queues behind it.
    await tester.pump(const Duration(seconds: 5));
    await settle(tester, frames: 6);

    // Walk the color-name ternary down: each deeper condition only runs
    // once every earlier color has failed to match.
    for (final (index, name) in [
      (2, 'Orange'),
      (3, 'Yellow'),
      (4, 'Green'),
      (5, 'Blue'),
    ]) {
      await tester.tap(chips.at(index));
      await settle(tester, frames: 6);
      expect(find.text('Selected: $name'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await settle(tester, frames: 6);
    }
  });

  testWidgets('the secondary icon button fires its snackbar', (tester) async {
    await mountPage(tester);

    // The pencil CustomIconButton of section 7 — scoped by icon so the
    // toggle list's own secondary buttons cannot satisfy the finder.
    final secondary = find.byWidgetPredicate(
      (w) =>
          w is CustomIconButton &&
          w.type == CustomIconButtonType.secondary &&
          w.icon is HeroIcon &&
          (w.icon as HeroIcon).icon == HeroIcons.pencil,
    );
    expect(secondary, findsOneWidget);
    await tester.ensureVisible(secondary);
    await settle(tester, frames: 4);
    await tester.tap(secondary);
    await settle(tester, frames: 6);

    expect(find.text('Secondary icon button pressed'), findsOneWidget);
    await drainSnackbars(tester);
  });
}
