import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The card's Edit journey in its own file: the edit page mounts through a
/// deferred route whose library stays warm for the rest of the process once
/// loaded, and a warm router stack from a previous deep link in the SAME
/// process wedges the second navigation — one journey per file keeps the
/// deferred-load state deterministic (every test file runs in its own
/// process under `flutter test`).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the event card opens an edit modal routed to the add-edit page in edit mode',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      const eventName = 'Gala de printemps';
      final event = EventCompleteTicketUrl.empty().copyWith(
        id: 'e-1',
        name: eventName,
        location: 'Amphi Marie Curie',
        associationId: 'a-1',
        association: Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
        start: DateTime(2026, 10, 10, 20),
        end: DateTime(2026, 10, 11, 2),
        decision: enums.Decision.approved,
      );
      when(
        () => scaffold.repository.calendarEventsAssociationsAssociationIdGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer((_) async => chopperListResponse([event]));
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

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/association_events',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 12);

      // Tap the card → bottom sheet with Edit / Delete actions.
      await scaffold.openModal(tester, find.text(eventName));
      expect(scaffold.isModalOpen(tester), isTrue);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Edit routes to the add-edit page in edit mode. The route is a
      // deferred import: its load completes on the real event loop between
      // pumps, so poll instead of pumping a fixed frame count.
      await scaffold.tapInModal(tester, find.text('Edit'));
      for (
        var i = 0;
        i < 20 && find.text('Edit event').evaluate().isEmpty;
        i++
      ) {
        await settle(tester, frames: 4);
      }
      // The form is prefilled from the tapped event (edit mode, not create).
      expect(find.text('Edit event'), findsOneWidget);
      expect(find.text(eventName), findsOneWidget);
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);
    },
  );
}
