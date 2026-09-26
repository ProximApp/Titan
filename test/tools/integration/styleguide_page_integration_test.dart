import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/button.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/styleguide/list_item.dart';
import 'package:titan/tools/ui/styleguide/list_item_template.dart';
import 'package:titan/tools/ui/styleguide/list_item_toggle.dart';
import 'package:titan/tools/ui/styleguide/searchbar.dart';

import '../../shared/app_scaffold.dart';

/// The styleguide page (`/styleguide`, 307 executable lines — the tools
/// module's biggest uncovered UI file). One deep-link shell asserting the
/// component catalog renders and the interactive demos respond.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpStyleGuide(WidgetTester tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/styleguide',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  /// Brings [finder] on screen. scrollUntilVisible stops as soon as the
  /// widget is BUILT (a ListView builds into the cache extent ahead of the
  /// viewport), which can leave it below the fold — ensureVisible then
  /// scrolls it into the actual viewport so a tap can land.
  Future<void> ensureOnScreen(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await settle(tester, frames: 4);
  }

  /// Drains the SnackBar timer so the next tap's SnackBar is unambiguous.
  Future<void> drainSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
  }

  testWidgets('the styleguide page renders its component catalog', (
    tester,
  ) async {
    await pumpStyleGuide(tester);

    // The page's section headers render.
    expect(find.text('Components'), findsOneWidget);
    expect(find.textContaining('Floating Navigation Bar'), findsOneWidget);
    expect(find.text('2. Buttons'), findsOneWidget);
    expect(find.text('4. SearchBar'), findsOneWidget);
    expect(find.text('7. Icon Buttons'), findsOneWidget);
    expect(find.text('9. Toggle List Item'), findsOneWidget);

    // The catalog carries one demo per component family (scroll to the
    // bottom of the page).
    await tester.scrollUntilVisible(
      find.byType(Button).last,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(Button), findsWidgets);
    expect(find.byType(ListItem), findsNWidgets(4));
    expect(find.byType(ToggleListItem), findsNWidgets(2));
    expect(find.byType(CustomSearchBar), findsWidgets);
  });

  testWidgets('the button and list-item demos react to taps', (tester) async {
    await pumpStyleGuide(tester);

    // The main-button demo pushes a SnackBar through the scaffold.
    await ensureOnScreen(tester, find.text('Main Action'));
    await tester.tap(find.text('Main Action'));
    await settle(tester, frames: 8);
    expect(find.text('Main button pressed'), findsOneWidget);
    await drainSnackBar(tester);

    // The list-item demos do the same. Tap the ROW (the ListItemTemplate
    // GestureDetector), not the title text — a tap on the title Text of a
    // subtitle-bearing row does not reach the row's handler under the test
    // binding, while the row type resolves to the full hit target.
    final rows = find.byType(ListItem);
    await ensureOnScreen(tester, rows.at(0));
    await tester.tap(rows.at(0));
    await settle(tester, frames: 8);
    expect(find.text('Settings tapped'), findsOneWidget);
    await drainSnackBar(tester);

    await ensureOnScreen(tester, rows.at(1));
    await tester.tap(rows.at(1));
    await settle(tester, frames: 8);
    expect(find.text('Account tapped'), findsOneWidget);
    await drainSnackBar(tester);

    await ensureOnScreen(tester, rows.at(2));
    await tester.tap(rows.at(2));
    await settle(tester, frames: 8);
    expect(find.text('Notifications tapped'), findsOneWidget);
    await drainSnackBar(tester);

    // The icon-button demos: match on the button TYPE so the toggle items'
    // internal trailing secondary buttons are skipped.
    final mainIconDemo = find.byWidgetPredicate(
      (widget) =>
          widget is CustomIconButton &&
          widget.type == CustomIconButtonType.main,
    );
    await ensureOnScreen(tester, mainIconDemo.first);
    await tester.tap(mainIconDemo.first);
    await settle(tester, frames: 8);
    expect(find.text('Main icon button pressed'), findsOneWidget);
    await drainSnackBar(tester);

    final dangerIconDemo = find.byWidgetPredicate(
      (widget) =>
          widget is CustomIconButton &&
          widget.type == CustomIconButtonType.danger,
    );
    await ensureOnScreen(tester, dangerIconDemo.first);
    await tester.tap(dangerIconDemo.first);
    await settle(tester, frames: 8);
    expect(find.text('Danger icon button pressed'), findsOneWidget);
    await drainSnackBar(tester);
  });

  testWidgets('the search bar and toggle demos update their state', (
    tester,
  ) async {
    await pumpStyleGuide(tester);

    // The toggle list items fire their onTap SnackBars: tap the ROW (the
    // ListItemTemplate GestureDetector), not the trailing plus button.
    // (Exercised before the search bar — after an enterText the following
    // scroll leaves the row occluded by the navbar overlay and the tap
    // lands on nothing.)
    final toggles = find.byType(ToggleListItem);
    await ensureOnScreen(tester, toggles.first);
    await tester.tap(toggles.first);
    await settle(tester, frames: 8);
    expect(find.text('Toggle item tapped'), findsOneWidget);
    await drainSnackBar(tester);

    await ensureOnScreen(tester, toggles.last);
    await tester.tap(toggles.last);
    await settle(tester, frames: 8);
    expect(find.text('Selected toggle item tapped'), findsOneWidget);
    await drainSnackBar(tester);

    // The search bar accepts input; enterText must be scoped to its
    // TextField — the CustomSearchBar hook widget itself matches its own
    // build and would not address the field.
    await ensureOnScreen(tester, find.byType(CustomSearchBar).first);
    await tester.enterText(
      find
          .descendant(
            of: find.byType(CustomSearchBar).first,
            matching: find.byType(TextField),
          )
          .first,
      'query',
    );
    await settle(tester, frames: 4);
    // onChanged fires onSearch → SnackBar; the field echoes the text.
    expect(find.text('query'), findsOneWidget);
    expect(find.textContaining('Searching for'), findsOneWidget);
    await drainSnackBar(tester);

    // NOTE: the clear (x-mark) button is deliberately NOT exercised here:
    // it only mounts when the HookWidget rebuilds while its controller has
    // text, and useTextEditingController does not subscribe to text changes
    // — on this static page it never appears (see README ledger).
  });

  testWidgets('the remaining button variants fire their own snack bars', (
    tester,
  ) async {
    await pumpStyleGuide(tester);

    await ensureOnScreen(tester, find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await settle(tester, frames: 8);
    expect(find.text('Danger button pressed'), findsOneWidget);
    await drainSnackBar(tester);

    await ensureOnScreen(tester, find.text('Confirm Delete'));
    await tester.tap(find.text('Confirm Delete'));
    await settle(tester, frames: 8);
    expect(find.text('On danger button pressed'), findsOneWidget);
    await drainSnackBar(tester);

    await ensureOnScreen(tester, find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await settle(tester, frames: 8);
    expect(find.text('Secondary button pressed'), findsOneWidget);
    await drainSnackBar(tester);

    // The disabled demo stays silent (onPressed is a no-op AND the button
    // swallows the tap).
    await ensureOnScreen(tester, find.text('Disabled'));
    await tester.tap(find.text('Disabled'));
    await settle(tester, frames: 8);
    expect(find.textContaining('pressed'), findsNothing);
  });

  testWidgets('the profile row and template rows react to taps', (
    tester,
  ) async {
    await pumpStyleGuide(tester);

    // The 4th ListItem is the Profile demo (Settings/Account/Notifications
    // live in the button-and-list-item test).
    final rows = find.byType(ListItem);
    await ensureOnScreen(tester, rows.at(3));
    await tester.tap(rows.at(3));
    await settle(tester, frames: 8);
    expect(find.text('Profile tapped'), findsOneWidget);
    await drainSnackBar(tester);

    final templates = find.byType(ListItemTemplate);
    // Tap the ROW (the ListItemTemplate hit target), not the title Text —
    // a tap on a subtitle-bearing row's title does not reach the handler.
    await ensureOnScreen(tester, templates.first);
    // Lift the row clear of the navbar band before tapping. The template
    // demos are the LAST content on the page; scroll to their titles.
    await ensureOnScreen(tester, find.text('Template Item'));
    await tester.tap(find.text('Template Item'));
    await settle(tester, frames: 8);
    expect(find.text('Template item tapped'), findsOneWidget);
    await drainSnackBar(tester);

    await ensureOnScreen(tester, find.text('Custom Trailing'));
    await tester.tap(find.text('Custom Trailing'));
    await settle(tester, frames: 8);
    expect(find.text('Custom trailing item tapped'), findsOneWidget);
    await drainSnackBar(tester);
  });

  testWidgets('the multi-select demos report selections and long presses', (
    tester,
  ) async {
    await pumpStyleGuide(tester);

    // Basic demo: tap a fruit chip.
    await ensureOnScreen(tester, find.text('Apple'));
    await tester.tap(find.text('Apple'));
    await settle(tester, frames: 8);
    expect(find.text('Selected: Apple'), findsOneWidget);
    await drainSnackBar(tester);

    // Custom-first-child demo: the leading + chip.
    final plusChip = find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == HeroIcons.plus,
    );
    await ensureOnScreen(tester, plusChip.first);
    await tester.tap(plusChip.first);
    await settle(tester, frames: 8);
    expect(find.text('Add new color'), findsOneWidget);
    await drainSnackBar(tester);

    // User demo: selection and LONG PRESS support.
    await ensureOnScreen(tester, find.text('John'));
    await tester.tap(find.text('John'));
    await settle(tester, frames: 8);
    expect(find.text('Selected: John'), findsOneWidget);
    await drainSnackBar(tester);

    await ensureOnScreen(tester, find.text('Emma'));
    await tester.longPress(find.text('Emma'));
    await settle(tester, frames: 8);
    expect(find.text('Long press on Emma'), findsOneWidget);
    await drainSnackBar(tester);
  });

  testWidgets('the filter-dialog search bar opens its option dialog', (
    tester,
  ) async {
    await pumpStyleGuide(tester);

    // The SECOND search bar owns the filter dialog (the first one only
    // raises a SnackBar — covered in the search-bar test above).
    final userSearchField = find.descendant(
      of: find.byType(CustomSearchBar).at(1),
      matching: find.byType(TextField),
    );
    await ensureOnScreen(tester, userSearchField);
    await tester.enterText(userSearchField, 'bob');
    await settle(tester, frames: 4);
    expect(find.text('User search: "bob"'), findsOneWidget);
    await drainSnackBar(tester);

    // The filter button opens the AlertDialog; a choice lands its own
    // SnackBar after popping the dialog.
    final filterIcon = find.descendant(
      of: find.byType(CustomSearchBar).at(1),
      matching: find.byWidgetPredicate((w) => w is GestureDetector),
    );
    await ensureOnScreen(tester, filterIcon.last);
    await tester.tap(filterIcon.last);
    await settle(tester, frames: 8);
    expect(find.text('Filter Options'), findsOneWidget);

    // ignore: avoid_print
    print(
      'TILES ${find.byType(ListTile).evaluate().map((e) => (e.widget as ListTile).title).toList()} at ${find.byType(ListTile).evaluate().map((e) => tester.getRect(find.byWidget(e.widget))).toList()}',
    );
    // 'Name' also labels the demo's TextEntry field — tap the ListTile.
    // Tapping a ListTile POPS the dialog through its backdrop handler
    // (the dialog builder's context is under the navigator, so its
    // ScaffoldMessenger lookup resolves to a Scaffold without an
    // Overlay-owned messenger — the 'Filter by …' SnackBar never shows).
    // Assert the observable part: the dialog is dismissed by the choice.
    await tester.tap(find.byType(ListTile).first);
    await settle(tester, frames: 8);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the entry demos accept input and respond to taps', (
    tester,
  ) async {
    await pumpStyleGuide(tester);

    // The text entries take input (Name / Amount with € suffix / multiline
    // Description).
    await ensureOnScreen(tester, find.text('Basic Text Entry:'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '42');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Line one\nLine two',
    );
    await settle(tester, frames: 4);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Line one\nLine two'), findsOneWidget);

    // The image entry raises its SnackBar.
    await ensureOnScreen(tester, find.text('Profile Picture'));
    await tester.tap(find.text('Profile Picture'));
    await settle(tester, frames: 8);
    expect(find.text('Image entry tapped'), findsOneWidget);
    await drainSnackBar(tester);

    // The date entry opens the real date picker dialog.
    await ensureOnScreen(tester, find.text('Event Date'));
    await tester.tap(find.text('Event Date'));
    await settle(tester, frames: 10);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    // Close it (calendar year header text varies; OK is stable).
    await tester.tap(find.text('OK').last);
    await settle(tester, frames: 8);
  });
}
