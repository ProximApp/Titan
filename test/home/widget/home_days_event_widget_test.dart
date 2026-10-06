import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/home/ui/days_event.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level test for `DaysEvent`, the home module's day column and the
/// first widget test the module has.
///
/// `DaysEvent` is in the fixed-size `CardLayout` ratchet
/// (`tools/widget/fixed_size_card_layouts_test.dart`) rather than the
/// fixed-width sweep: it pins `height: 135` and passes
/// `width: double.infinity`, so the width-based detector cannot see it — the
/// height is an argument to a constructor call, not a `SizedBox`.
///
/// The shape worth measuring is the last `Row` inside each card. It is
/// `spaceBetween` with a `Text(event.location)` and a
/// `Text(event.association.name)` and NOT ONE `Expanded`, so the two compete
/// for a card that is 300px wide minus its own padding, and a long location
/// plus a long association name is the ordinary case for a real association.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  const longName = 'Conference annuelle de l association des etudiants';

  EventCompleteTicketUrl event({
    String name = longName,
    String location = 'Amphitheatre Borda, campus de Pessac, Gironde',
    String associationName = 'Association des etudiants en medecine',
    String? description,
    DateTime? start,
    DateTime? end,
    bool allDay = false,
  }) => EventCompleteTicketUrl.empty().copyWith(
    id: 'e-1',
    name: name,
    location: location,
    description: description,
    allDay: allDay,
    start: start ?? DateTime(2100, 3, 4, 18, 0),
    end: end ?? DateTime(2100, 3, 4, 22, 0),
    association: Association.empty().copyWith(id: 'a-1', name: associationName),
  );

  testWidgets(
    'a day with one event fits a long name, location and association',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: DaysEvent(
              day: 'Wednesday 4 March',
              now: DateTime(2026, 1, 1),
              events: [event()],
            ),
          ),
        ),
        container,
        appFonts: true,
      );

      // Non-vacuity: the card mounted and rendered its three text lines.
      expect(find.byType(DaysEvent), findsOneWidget);
      expect(find.text(longName), findsOneWidget);
      expect(
        find.text('Amphitheatre Borda, campus de Pessac, Gironde'),
        findsOneWidget,
      );
      expect(
        find.text('Association des etudiants en medecine'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    },
  );

  testWidgets('a day with several events fits all of them', (tester) async {
    // Three stacked 135px cards in a Column, which is the shape the home page
    // actually builds for a busy day.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: DaysEvent(
            day: 'Wednesday 4 March',
            now: DateTime(2026, 1, 1),
            events: [
              for (var i = 0; i < 3; i++)
                event(
                  name: '$longName $i',
                  location: 'Salle$i, campus de Pessac',
                  associationName: 'Association numero $i',
                ),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(DaysEvent), findsOneWidget);
    expect(find.textContaining('Association numero'), findsNWidgets(3));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('a day fits its past, ongoing and future event colours', (
    tester,
  ) async {
    // The card picks its gradient from three comparisons against `now`, and
    // the text colour flips with it, so the three branches are three
    // different foreground colours in the same layout.
    final now = DateTime(2100, 3, 4, 20, 0);
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: DaysEvent(
            day: 'Wednesday 4 March',
            now: now,
            events: [
              event(
                name: 'Finished',
                start: DateTime(2100, 3, 4, 8, 0),
                end: DateTime(2100, 3, 4, 10, 0),
              ),
              event(
                name: 'Ongoing',
                start: DateTime(2100, 3, 4, 18, 0),
                end: DateTime(2100, 3, 4, 22, 0),
              ),
              event(
                name: 'Upcoming',
                start: DateTime(2100, 3, 4, 23, 0),
                end: DateTime(2100, 3, 5, 1, 0),
              ),
            ],
          ),
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(DaysEvent), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Ongoing'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets(
    'a day fits a multi-line description truncated to its first line',
    (tester) async {
      // The description is cut to its first `\n` and gets a "..." when there
      // was more, so the card's last line is one line by construction.
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: DaysEvent(
              day: 'Wednesday 4 March',
              now: DateTime(2026, 1, 1),
              events: [event(description: 'First line of the description')],
            ),
          ),
        ),
        container,
        appFonts: true,
      );

      expect(find.text('First line of the description'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    },
  );

  testWidgets('a day with no events renders only its heading', (tester) async {
    // `...events.map(...)` over an empty list: the Column is the heading and
    // nothing else, which is the empty state the home page shows.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(
        body: DaysEvent(
          day: 'Wednesday 4 March',
          now: DateTime(2026, 1, 1),
          events: const [],
        ),
      ),
      container,
      appFonts: true,
    );

    expect(find.byType(DaysEvent), findsOneWidget);
    expect(find.text('Wednesday 4 March'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
