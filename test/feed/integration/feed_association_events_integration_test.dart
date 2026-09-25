import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /feed/association_events lists my associations and their events',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [
          Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
          Association(name: 'PACES', groupId: 'g-2', id: 'a-2'),
        ],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      const bdeEvent = 'Gala de printemps';
      when(
        () => scaffold.repository.calendarEventsAssociationsAssociationIdGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer(
        (_) async => chopperListResponse([
          EventCompleteTicketUrl.empty().copyWith(
            id: 'e-1',
            name: bdeEvent,
            location: 'Amphi Marie Curie',
            associationId: 'a-1',
            association: Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
            decision: enums.Decision.approved,
          ),
        ]),
      );
      // The card fetches its image on mount.
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

      // Association chips from myAssociationsGet (first selected by default).
      expect(find.text('BDE'), findsOneWidget);
      expect(find.text('PACES'), findsOneWidget);
      expect(find.text('Manage association events'), findsOneWidget);
      // The event card renders name + location from the real endpoint.
      expect(find.text(bdeEvent), findsOneWidget);
      expect(find.text('Amphi Marie Curie'), findsOneWidget);

      // Switching the chip loads the other association's events.
      when(
        () => scaffold.repository.calendarEventsAssociationsAssociationIdGet(
          associationId: 'a-2',
        ),
      ).thenAnswer((_) async => chopperListResponse([]));
      await tester.tap(find.text('PACES'));
      await settle(tester, frames: 10);
      expect(find.text('No association events'), findsOneWidget);
      expect(find.text(bdeEvent), findsNothing);
    },
  );
}
