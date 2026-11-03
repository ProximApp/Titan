import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The edit-mode corners `feed_edit_event_residual_integration_test.dart`
/// leaves: an event that already carries a ticketing opening date (the
/// controller prefill that formats `ticketUrlOpening`, lines 74-76), saved
/// WITHOUT a poster (the update success arm that must not wait on an upload,
/// lines 553-554), with an association that is not the only one the user
/// belongs to — so `selectedAssociation` starts null and the payload has to
/// fall back to `Association.empty()` (line 533).
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
    ticketUrl: 'https://billetterie.example/gala',
    ticketUrlOpening: DateTime(2026, 10, 5, 18),
    decision: enums.Decision.approved,
  );

  testWidgets(
    'editing an event with an SG date and no new poster saves directly',
    (tester) async {
      final container = scaffold.makeContainer(
        // Two associations: nothing is pre-selected, which is the branch the
        // payload's Association.empty() fallback exists for.
        myAssociations: [
          Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
          Association(name: 'BDA', groupId: 'g-1', id: 'a-2'),
        ],
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

      EventEdit? capturedEdit;
      when(
        () => scaffold.repository.calendarEventsEventIdPatch(
          eventId: any(named: 'eventId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedEdit = inv.namedArguments[#body] as EventEdit;
        return chopperResponse<EventCompleteTicketUrl>(
          EventCompleteTicketUrl.empty(),
        );
      });

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

      // The SG date controller is prefilled from ticketUrlOpening, formatted
      // with the locale's date + time — an event saved with an opening date
      // must show it back, not an empty row.
      expect(
        find.text('10/5/2026 18:00'),
        findsOneWidget,
        reason:
            'the ticketing opening date has to survive a reload into the form',
      );

      // Save without touching the poster: the update succeeds and the page
      // reports "Event modified" without ever calling the image upload.
      await tester.dragUntilVisible(
        find.text('Edit event'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -80),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Edit event'), warnIfMissed: false);
      await settle(tester, frames: 14);

      expect(capturedEdit, isNotNull);
      expect(capturedEdit!.ticketUrlOpening, isNotNull);
      expect(
        capturedEdit!.ticketUrlOpening,
        DateTime(2026, 10, 5, 18),
        reason: 'the opening date must round-trip through the form unchanged',
      );
      verifyNever(
        () => scaffold.repository.calendarEventsEventIdImagePost(
          eventId: any(named: 'eventId'),
          image: any(named: 'image'),
        ),
      );
      expect(find.text('Event modified'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
