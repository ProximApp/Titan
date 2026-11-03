import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/event/providers/event_provider.dart';
import 'package:titan/event/ui/pages/event_pages/add_edit_event_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';

import '../../shared/app_scaffold.dart';

/// Page-level coverage for `AddEditEventPage` — the event module's biggest
/// uncovered file. The four flows drive the REAL form: pickers, validators,
/// the recurrence rule generation and the repository calls behind add /
/// update.
///
/// The page is mounted directly instead of through a deep link: `EventRouter`
/// is currently NOT registered in `AppRouter` (no production path reaches
/// the page), so `/event/add_edit` resolves to /notfound. The success path's
/// `QR.back()` is exercised anyway — with an empty qlevar history it is a
/// documented no-op (`PopResult.NotPopped`).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubListAnswers({List<EventCompleteTicketUrl>? confirmed}) {
    when(() => scaffold.repository.calendarEventsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse(confirmed ?? <EventCompleteTicketUrl>[]),
    );
    when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse([
        RoomComplete.empty().copyWith(id: 'r-1', name: 'Amphi Darwin'),
      ]),
    );
  }

  testWidgets('the add form builds an all-day event in a room and posts it', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    stubListAnswers();

    EventBaseCreation? captured;
    when(() => scaffold.repository.calendarEventsPost(body: any(named: 'body')))
        .thenAnswer((inv) async {
          captured = inv.namedArguments[#body] as EventBaseCreation;
          return chopperResponse(
            EventCompleteTicketUrl.empty().copyWith(
              id: 'e-new',
              name: captured?.name ?? '',
            ),
          );
        });

    await scaffold.pumpWidgetApp(
      tester,
      AddEditEventPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 4);
    expect(find.text('Add an event'), findsOneWidget);

    // Required text fields in tree order: name, organizer, location,
    // then the two all-day date entries and the description.
    await tester.enterText(find.byType(TextFormField).at(0), 'Soirée Kino');
    await tester.enterText(find.byType(TextFormField).at(1), 'BDE Info');
    await tester.enterText(
      find.byType(TextFormField).at(5),
      'Deux films, une discussion',
    );
    await settle(tester, frames: 2);

    // All day: the date entries switch to day pickers.
    await tester.tap(find.text('All day'));
    await settle(tester, frames: 2);

    // Room mode replaces the location field with the rooms strip.
    await tester.tap(find.text('Room'));
    await settle(tester, frames: 6);
    expect(find.text('Amphi Darwin'), findsOneWidget);
    await tester.tap(find.text('Amphi Darwin'));
    await settle(tester, frames: 2);

    // Both pickers: accept the preselected (today) day.
    await tester.ensureVisible(find.byType(DateEntry).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DateEntry).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await settle(tester, frames: 6);
    await tester.ensureVisible(find.byType(DateEntry).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DateEntry).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await settle(tester, frames: 6);

    // Submit sits below the fold.
    await tester.dragUntilVisible(
      find.text('Add'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 12);

    expect(captured, isNotNull);
    expect(captured!.name, 'Soirée Kino');
    expect(captured!.associationId, 'BDE Info');
    expect(captured!.location, 'Amphi Darwin');
    expect(captured!.description, 'Deux films, une discussion');
    expect(captured!.allDay, isTrue);
    final today = DateTime.now();
    expect(captured!.start, DateTime(today.year, today.month, today.day));
    expect(captured!.end, DateTime(today.year, today.month, today.day));
    expect(find.text('Event added'), findsOneWidget);

    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets(
    'a recurrence without a day is refused, then the rrule is posted',
    (tester) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);
      stubListAnswers();

      EventBaseCreation? captured;
      when(
        () => scaffold.repository.calendarEventsPost(body: any(named: 'body')),
      ).thenAnswer((inv) async {
        captured = inv.namedArguments[#body] as EventBaseCreation;
        return chopperResponse(
          EventCompleteTicketUrl.empty().copyWith(
            id: 'e-new',
            name: captured?.name ?? '',
          ),
        );
      });

      await scaffold.pumpWidgetApp(
        tester,
        AddEditEventPage(),
        container,
        surface: const ui.Size(900, 1400),
      );
      await settle(tester, frames: 4);

      await tester.enterText(find.byType(TextFormField).at(0), 'Réunion CP');
      await tester.enterText(find.byType(TextFormField).at(1), 'BDE Info');
      await settle(tester, frames: 2);

      // Recurrence swaps the date entries for the day rows, the interval
      // and the recurrence end date.
      await tester.tap(find.text('Recurrence'));
      await settle(tester, frames: 2);
      expect(find.text('Monday'), findsOneWidget);

      // Field order with the recurrence branch open: name, organizer,
      // interval, start hour, end hour, recurrence end date, location,
      // description — every one of them is a required validator.
      await tester.enterText(find.byType(TextFormField).at(6), 'Salle 203');
      await tester.enterText(find.byType(TextFormField).at(7), 'Point hebdo');
      await settle(tester, frames: 2);

      // The two hours and the recurrence end date are required; OK keeps
      // the preselected values.
      await tester.ensureVisible(find.byType(DateEntry).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DateEntry).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await settle(tester, frames: 6);
      await tester.ensureVisible(find.byType(DateEntry).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DateEntry).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await settle(tester, frames: 6);
      // The recurrence end must land AFTER the start hour, otherwise
      // syncfusion's rule generator returns an empty string (UNTIL would
      // be midnight today, before the start time) — pick the 5th of next
      // month.
      await tester.ensureVisible(find.byType(DateEntry).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DateEntry).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await settle(tester, frames: 6);

      await tester.dragUntilVisible(
        find.text('Add'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);

      // First submit: no day ticked → the guard toast, no POST.
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);
      expect(find.text('No day selected'), findsOneWidget);
      verifyNever(
        () => scaffold.repository.calendarEventsPost(body: any(named: 'body')),
      );

      // Tick Monday and resubmit: the weekly rule is generated and posted.
      await tester.tap(find.text('Monday'));
      await settle(tester, frames: 2);
      await tester.tap(find.text('Add'));
      await settle(tester, frames: 12);

      expect(captured, isNotNull);
      expect(captured!.name, 'Réunion CP');
      expect(captured!.allDay, isFalse);
      expect(captured!.recurrenceRule, contains('FREQ=WEEKLY'));
      expect(captured!.recurrenceRule, contains('INTERVAL=1'));
      expect(find.text('Event added'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );

  testWidgets('an end date before the start date is refused', (tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    stubListAnswers();

    await scaffold.pumpWidgetApp(
      tester,
      AddEditEventPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 4);

    await tester.enterText(find.byType(TextFormField).at(0), 'Sortie');
    await tester.enterText(find.byType(TextFormField).at(1), 'BDE Info');
    await tester.enterText(find.byType(TextFormField).at(4), 'Salle 1');
    await tester.enterText(
      find.byType(TextFormField).at(5),
      'Un concert, une nuit',
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('All day'));
    await settle(tester, frames: 2);

    // Start: the first of NEXT month (the picker only offers today and
    // later), so it is after the end no matter which day this runs.
    await tester.ensureVisible(find.byType(DateEntry).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DateEntry).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await settle(tester, frames: 6);
    // End: today.
    await tester.ensureVisible(find.byType(DateEntry).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DateEntry).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await settle(tester, frames: 6);
    await tester.dragUntilVisible(
      find.text('Add'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 12);

    expect(find.text('End date must be after start date'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.calendarEventsPost(body: any(named: 'body')),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('the edit form prefills and patches the event', (tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    // The edited event must also sit in the confirmed list: `update()`
    // replaces the entry by id and returns false on a miss (edits always
    // start from a list in production).
    final start = DateTime.now();
    final seeded = EventCompleteTicketUrl.empty().copyWith(
      id: 'e-9',
      name: 'Old name',
      description: 'Old description',
      associationId: 'assoc-1',
      location: 'Salle 104',
      allDay: false,
      recurrenceRule: '',
      start: DateTime(start.year, start.month, start.day, 18),
      end: DateTime(start.year, start.month, start.day, 20),
    );
    stubListAnswers(confirmed: [seeded]);
    container.read(eventProvider.notifier).setEvent(seeded);

    EventEdit? captured;
    when(
      () => scaffold.repository.calendarEventsEventIdPatch(
        eventId: 'e-9',
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      captured = inv.namedArguments[#body] as EventEdit;
      return chopperResponseVoid();
    });

    await scaffold.pumpWidgetApp(
      tester,
      AddEditEventPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 4);
    expect(find.text('Edit an event'), findsOneWidget);

    // The form opens prefilled from the seeded event.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!
          .text,
      'Old name',
    );

    await tester.dragUntilVisible(
      find.text('Edit'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 12);

    expect(captured, isNotNull);
    expect(captured!.name, 'Old name');
    expect(captured!.location, 'Salle 104');
    expect(captured!.allDay, isFalse);
    expect(find.text('Event edited'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets(
    'editing a recurring event decodes its rule into the form fields',
    (tester) async {
      final container = scaffold.makeContainer(userId: 'user-1');
      addTearDown(container.dispose);

      // A rule the BACKEND produced: the page reads the day list, the
      // interval and the UNTIL date back out of it with string splits, so a
      // shape disagreement silently renders "1" and an empty end date. This
      // pins the decode, not just the encode the add flow already covers.
      final start = DateTime.now();
      final until = DateTime(start.year + 1, 3, 31);
      final seeded = EventCompleteTicketUrl.empty().copyWith(
        id: 'e-rec',
        name: 'Weekly standup',
        description: 'Point hebdo',
        associationId: 'assoc-1',
        location: 'Salle 104',
        allDay: false,
        recurrenceRule:
            'FREQ=WEEKLY;BYDAY=MO,WE;INTERVAL=2;UNTIL='
            '${DateFormat('yyyyMMdd').format(until)}',
        start: DateTime(start.year, start.month, start.day, 18),
        end: DateTime(start.year, start.month, start.day, 20),
      );
      stubListAnswers(confirmed: [seeded]);
      container.read(eventProvider.notifier).setEvent(seeded);

      await scaffold.pumpWidgetApp(
        tester,
        AddEditEventPage(),
        container,
        surface: const ui.Size(900, 1400),
      );
      await settle(tester, frames: 4);
      expect(find.text('Edit an event'), findsOneWidget);

      // Recurrence branch open + not all-day, so the tree order is: name,
      // organizer, interval, start hour, end hour, recurrence end date,
      // location, description.
      String fieldAt(int index) => tester
          .widget<TextFormField>(find.byType(TextFormField).at(index))
          .controller!
          .text;
      expect(fieldAt(2), '2', reason: 'INTERVAL=2 must decode to "2"');
      expect(fieldAt(3), '18:00');
      expect(fieldAt(4), '20:00');
      expect(
        fieldAt(5),
        DateFormat.yMd('en_US').format(until),
        reason: 'UNTIL must decode into the recurrence end date',
      );
    },
  );

  testWidgets('turning on all-day clears the dates already entered', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);

    final start = DateTime.now();
    final seeded = EventCompleteTicketUrl.empty().copyWith(
      id: 'e-9',
      name: 'Old name',
      associationId: 'assoc-1',
      location: 'Salle 104',
      allDay: false,
      recurrenceRule: '',
      start: DateTime(start.year, start.month, start.day, 18),
      end: DateTime(start.year, start.month, start.day, 20),
    );
    stubListAnswers(confirmed: [seeded]);
    container.read(eventProvider.notifier).setEvent(seeded);

    await scaffold.pumpWidgetApp(
      tester,
      AddEditEventPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 4);

    List<String> dateValues() => tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((field) => field.controller?.text ?? '')
        .toList();
    // A timed event prefills date AND hour ("11/1/2026 18:00"), so the hour
    // is checked as a suffix rather than as the whole value.
    bool hasHour(String hour) =>
        dateValues().any((value) => value.endsWith(hour));
    expect(hasHour('18:00'), isTrue, reason: '${dateValues()}');

    // An hour that survived the switch would be posted as a timestamp on a
    // day the user only chose as a date, so the toggle clears all three.
    await tester.tap(find.text('All day'));
    await settle(tester, frames: 4);

    expect(hasHour('18:00'), isFalse, reason: '${dateValues()}');
    expect(hasHour('20:00'), isFalse, reason: '${dateValues()}');
  });
}
