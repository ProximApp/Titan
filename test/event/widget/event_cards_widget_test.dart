import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/event/ui/components/edit_delete_button.dart';
import 'package:titan/event/ui/components/event_ui.dart';
import 'package:titan/event/ui/pages/admin_page/list_event.dart';
import 'package:titan/event/ui/pages/event_pages/checkbox_entry.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/card_button.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the event module — the first widget tests it has.
///
/// The shared sweeps know one event widget: `EventUi`, mounted from the
/// registry with a long name and everything else EMPTY, so the shapes this
/// file measures were never measured before: the `spaceBetween` location /
/// association row with BOTH sides long (the exact defect ledger #49 fixed
/// one module over in `DaysEvent`), the three date-driven backgrounds, the
/// three variants — list (`EventUi` default), detail (`isDetailPage`) and
/// the admin strip card (`isDetailPage + isAdmin`, the shape `ListEvent`
/// mounts inside its 235px `HorizontalListView`) — and the admin action row
/// whose confirm/decline taps must no-op once the decision is already made.
///
/// The module's PAGES (main, detail, admin, add/edit) stay at integration
/// level: the mount ratchet exempts `EventMainPage` as "a PAGE. Rendered by
/// event/feed's integration tests". What is here are the leaves.
///
/// Deliberately never tapped: anything that navigates through `QR.to` (the
/// list variant's info icon and Edit button, `ListEvent`'s onEdit/onCopy)
/// — qlevar's routes are not registered at widget level, so every tap here
/// is either a test-owned callback or a local state flip.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  const longName = 'Gala annuel des associations de l universite Bordeaux';
  const longLocation = 'Amphitheatre Borda, campus de Pessac, Gironde';
  const longAssociation = 'Bureau des Etudiants de l ENSEIRB MATMECA';
  const threeLines =
      'Premiere ligne de la description tres longue\n'
      'Deuxieme ligne elle aussi fort longue\n'
      'Troisieme ligne qui ne doit pas apparaitre';

  EventCompleteTicketUrl event({
    String name = longName,
    String location = longLocation,
    String associationName = longAssociation,
    String? description = threeLines,
    DateTime? start,
    DateTime? end,
    Decision decision = Decision.pending,
  }) => EventCompleteTicketUrl.empty().copyWith(
    id: 'e-1',
    name: name,
    location: location,
    description: description,
    association: Association.empty().copyWith(id: 'a-1', name: associationName),
    start: start ?? DateTime(2100, 3, 4, 18, 0),
    end: end ?? DateTime(2100, 3, 4, 22, 0),
    decision: decision,
  );

  /// The card's outer `Container` — the first `Container` under the widget,
  /// which carries the date-driven `BoxDecoration`.
  BoxDecoration decorationOf(WidgetTester tester, int index) {
    final card = find.byType(EventUi).at(index);
    final box = tester.widget<Container>(
      find.descendant(of: card, matching: find.byType(Container)).first,
    );
    return box.decoration! as BoxDecoration;
  }

  testWidgets('the list variant fits long strings on both row sides', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    var infoTaps = 0;

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: EventUi(event: event(), onInfo: () => infoTaps++),
        ),
      ),
      container,
      appFonts: true,
    );

    // Non-vacuity: every line of the card rendered.
    expect(find.byType(EventUi), findsOneWidget);
    expect(find.text(longName), findsOneWidget);
    expect(find.text(longLocation), findsOneWidget);
    expect(find.text(longAssociation), findsOneWidget);
    expect(find.textContaining('Premiere ligne'), findsOneWidget);
    // Only the first two description lines are joined, with '...' appended —
    // the third line must never reach the card.
    expect(find.textContaining('Troisieme'), findsNothing);
    expect(find.textContaining('...'), findsWidgets);
    expect(find.text('pending'), findsOneWidget);
    // The chrome: edit + delete, and the info icon that opens the detail.
    expect(find.byType(EditDeleteButton), findsNWidgets(2));
    expect(
      find.byType(HeroIcon),
      findsOneWidget,
    ); // The 250px pin the width sweep registers this card for. The first
    // Container under EventUi is the outer one, whose render box spans the
    // 40px horizontal margin on each side too: 250 + 80 = 330.
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(EventUi),
                  matching: find.byType(Container),
                )
                .first,
          )
          .width,
      330,
    );
    expect(tester.takeException(), isNull);

    // Tapping the title (not the icon — that one navigates through QR)
    // reaches the card's own onTap.
    await tester.tap(find.text(longName));
    await tester.pump();
    expect(infoTaps, 1);

    await scaffold.unmountApp(tester);
  });

  testWidgets('past, ongoing and future events paint different cards', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final now = DateTime.now();

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              EventUi(event: event(start: now.add(const Duration(days: 3)))),
              EventUi(
                event: event(
                  start: now.subtract(const Duration(hours: 1)),
                  end: now.add(const Duration(hours: 3)),
                ),
              ),
              EventUi(
                event: event(
                  start: now.subtract(const Duration(days: 3)),
                  end: now.subtract(const Duration(days: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(EventUi), findsNWidgets(3));
    // The gradient branch each date range asks for.
    expect(
      decorationOf(tester, 0).gradient,
      isA<LinearGradient>().having((g) => g.colors, 'colors', [
        Colors.white,
        Colors.white,
      ]),
      reason: 'a future event is the white card',
    );
    expect(
      decorationOf(tester, 1).gradient,
      isA<LinearGradient>().having((g) => g.colors, 'colors', [
        ColorConstants.gradient1,
        ColorConstants.gradient2,
      ]),
      reason: 'an ongoing event is the gradient card',
    );
    expect(
      decorationOf(tester, 2).gradient,
      isA<LinearGradient>().having((g) => g.colors, 'colors', [
        Colors.grey.shade700,
        Colors.grey.shade800,
      ]),
      reason: 'a past event is the grey card',
    );
    // The text colour follows the same dates.
    TextStyle titleStyle(int index) {
      final text = tester.widget<AutoSizeText>(
        find
            .descendant(
              of: find.byType(EventUi).at(index),
              matching: find.byType(AutoSizeText),
            )
            .first,
      );
      return text.style!;
    }

    expect(titleStyle(0).color, Colors.black, reason: 'future title');
    expect(titleStyle(2).color, Colors.white, reason: 'past title');
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the detail variant drops the list chrome', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    var infoTaps = 0;

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: EventUi(
            event: event(),
            isDetailPage: true,
            onInfo: () => infoTaps++,
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(EventUi), findsOneWidget);
    expect(find.text(longName), findsOneWidget);
    expect(find.text('pending'), findsOneWidget);
    // No edit/delete row, no info icon in the detail variant.
    expect(find.byType(EditDeleteButton), findsNothing);
    expect(find.byType(HeroIcon), findsNothing);
    expect(tester.takeException(), isNull);

    // The card's onTap guards on `!isDetailPage || isAdmin` — on a plain
    // detail card it must NOT forward the tap to onInfo.
    await tester.tap(find.text(longName));
    await tester.pump();
    expect(infoTaps, 0);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the admin strip card fits the 235px box and fires its actions', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    var edit = 0, copy = 0, confirm = 0, decline = 0, info = 0;

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Center(
          child: SizedBox(
            height: 235,
            child: EventUi(
              event: event(),
              isDetailPage: true,
              isAdmin: true,
              onEdit: () => edit++,
              onCopy: () => copy++,
              onConfirm: () => confirm++,
              onDecline: () => decline++,
              onInfo: () => info++,
            ),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    // The strip card: no edit/delete row (detail), the four admin buttons.
    expect(find.byType(EventUi), findsOneWidget);
    expect(find.byType(EditDeleteButton), findsNothing);
    expect(find.byType(CardButton), findsNWidgets(4));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(longName));
    await tester.pump();
    expect(info, 1, reason: 'the admin card forwards its onTap to onInfo');

    for (final i in [0, 1, 2, 3]) {
      await tester.tap(find.byType(CardButton).at(i));
      await tester.pump();
    }
    expect(edit, 1, reason: 'pencil -> onEdit');
    expect(copy, 1, reason: 'document -> onCopy');
    expect(confirm, 1, reason: 'check -> onConfirm for a pending decision');
    expect(decline, 1, reason: 'x -> onDecline for a pending decision');
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('confirm and decline no-op once the decision is made', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    var confirm = 0, decline = 0;

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Center(
          child: SizedBox(
            height: 235,
            child: EventUi(
              event: event(decision: Decision.approved),
              isDetailPage: true,
              isAdmin: true,
              onConfirm: () => confirm++,
              onDecline: () => decline++,
            ),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    // CardButton order: pencil, document, check, x.
    await tester.tap(find.byType(CardButton).at(2));
    await tester.pump();
    expect(confirm, 0, reason: 'an approved event cannot be confirmed again');

    await tester.tap(find.byType(CardButton).at(3));
    await tester.pump();
    expect(decline, 1, reason: 'declining an approved event still works');
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('EditDeleteButton paints the colors it is handed', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Center(
          child: EditDeleteButton(
            backGroundColor: Colors.red,
            borderColor: Colors.blue,
            child: const Text('Supprimer'),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.text('Supprimer'), findsOneWidget);
    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(EditDeleteButton),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.red);
    expect((decoration.border as Border).top.color, Colors.blue);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('CheckBoxEntry flips its notifier and calls onChanged', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final notifier = ValueNotifier<bool>(false);
    addTearDown(notifier.dispose);
    var changed = 0;

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<bool>(
            valueListenable: notifier,
            builder: (context, value, _) => CheckBoxEntry(
              title: 'Recurrence',
              valueNotifier: notifier,
              onChanged: () => changed++,
            ),
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(CheckBoxEntry), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    // Tapping the ROW flips the notifier (and, through the listener above,
    // the checkbox) — it deliberately does not call onChanged.
    await tester.tap(find.text('Recurrence'));
    await tester.pump();
    expect(notifier.value, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(changed, 0);

    // Tapping the CHECKBOX calls onChanged — the branch the add/edit page
    // uses to clear its date controllers.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(changed, 1);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('ListEvent counts, pluralizes and expands its strip', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final now = DateTime.now();
    final upcoming = [
      event(name: 'Gala', start: now.add(const Duration(days: 1))),
      event(name: 'Conference', start: now.add(const Duration(days: 2))),
    ];

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ListEvent(events: upcoming, title: 'Event'),
        ),
      ),
      container,
      appFonts: true,
    );

    // canToggle starts the list COLLAPSED: header counts only, no cards.
    expect(find.text('Events (2)'), findsOneWidget);
    expect(find.byType(EventUi), findsNothing);

    await tester.tap(find.text('Events (2)'));
    await tester.pump();
    expect(
      find.byType(EventUi),
      findsNWidgets(2),
      reason: 'the strip reveals the two upcoming events',
    );
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('ListEvent history filter and empty state', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final past = event(
      name: 'Gala passe',
      start: DateTime(2020, 3, 4),
      end: DateTime(2020, 3, 5),
    );

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ListEvent(events: [past], title: 'Event', isHistory: true),
        ),
      ),
      container,
      appFonts: true,
    );

    // Singular: exactly one past event matches the history filter.
    expect(find.text('Event (1)'), findsOneWidget);
    await tester.tap(find.text('Event (1)'));
    await tester.pump();
    expect(find.byType(EventUi), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);

    // A list with nothing in the filtered half renders no header at all.
    final container2 = scaffold.makeContainer();
    addTearDown(container2.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ListEvent(events: [past], title: 'Event'),
        ),
      ),
      container2,
      appFonts: true,
    );

    expect(find.byType(ListEvent), findsOneWidget);
    expect(find.textContaining('Event'), findsNothing);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
