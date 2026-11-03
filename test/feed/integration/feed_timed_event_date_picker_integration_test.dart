import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The TIMED half of the start/end rows on add_event_page.
///
/// Each row's tap handler picks its dialog from the all-day box:
/// `getOnlyDayDate` when it is ticked, `getFullDate` (date dialog THEN time
/// dialog, both real) when it is not. Every existing file edits an all-day
/// event and therefore only ever runs the day-only arm; the timed arm — the
/// one a normal evening event uses — was never executed, so a broken
/// formatting or a dropped time dialog on it would have shipped unnoticed.
///
/// The journey is the edit-residual one (association-events card → modal →
/// Edit); the event here is timed, so the two controllers arrive prefilled
/// with hour-stamped text and the picked values can be told apart from them.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  EventCompleteTicketUrl event() => EventCompleteTicketUrl.empty().copyWith(
    id: 'e-1',
    name: 'Gala de printemps',
    location: 'Amphi Marie Curie',
    associationId: 'a-1',
    association: Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
    start: DateTime(2026, 10, 10, 20),
    end: DateTime(2026, 10, 11, 2),
    allDay: false,
    decision: enums.Decision.approved,
  );

  /// The current text of the field carrying [label]: a picked value is read
  /// back from the controller, not guessed from the dialog.
  String textOf(WidgetTester tester, String label) => tester
      .widget<TextField>(find.widgetWithText(TextField, label))
      .controller!
      .text;

  testWidgets(
    'a timed event fills its start and end rows through the date and time dialogs',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(
        () => scaffold.repository.calendarEventsAssociationsAssociationIdGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer((_) async => chopperListResponse([event()]));
      when(
        () => scaffold.repository.calendarEventsEventIdImageGet(
          eventId: any(named: 'eventId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          [],
          error: 'File does not exist',
        ),
      );
      when(() => scaffold.repository.feedNewsGet())
          .thenAnswer((_) async => chopperListResponse(<News>[]));

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/association_events',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 12);

      await scaffold.openModal(tester, find.text('Gala de printemps'));
      await scaffold.tapInModal(tester, find.text('Edit'));
      for (
        var i = 0;
        i < 20 && find.text('Edit event').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      expect(find.text('Edit event'), findsOneWidget);

      // Timed prefill: hour-stamped, unlike the all-day branch's day-only
      // text (both months here are two-digit, so the format is unambiguous).
      expect(textOf(tester, 'Start date'), '10/10/2026 20:00');
      expect(textOf(tester, 'End date'), '10/11/2026 02:00');

      // Start row: real showDatePicker → showTimePicker, both OK'd.
      await tester.tap(find.text('Start date'));
      await settle(tester, frames: 8);
      await tester.tap(find.text('OK').first);
      await settle(tester, frames: 8);
      await tester.tap(find.text('OK').first);
      await settle(tester, frames: 8);

      final pickedStart = textOf(tester, 'Start date');
      expect(pickedStart, isNot('10/10/2026 20:00'));
      expect(
        pickedStart,
        matches(RegExp(r'^\d{1,2}/\d{1,2}/\d{4} \d{2}:\d{2}$')),
      );

      // End row: same two dialogs, reached after scrolling (the submit row
      // and the poster push the end row down at this viewport).
      await tester.dragUntilVisible(
        find.text('End date'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('End date'));
      await settle(tester, frames: 8);
      await tester.tap(find.text('OK').first);
      await settle(tester, frames: 8);
      await tester.tap(find.text('OK').first);
      await settle(tester, frames: 8);

      final pickedEnd = textOf(tester, 'End date');
      expect(pickedEnd, isNot('10/11/2026 02:00'));
      expect(
        pickedEnd,
        matches(RegExp(r'^\d{1,2}/\d{1,2}/\d{4} \d{2}:\d{2}$')),
      );
      // Nothing was saved: the form is still the edit form.
      expect(find.text('Edit event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
