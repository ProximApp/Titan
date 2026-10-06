import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    'deep link to /feed/add_edit_event creates an event through the real calendarEventsPost',
    (tester) async {
      final container = scaffold.makeContainer(
        myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);

      // The create form reloads the feed after success.
      when(
        () => scaffold.repository.feedNewsGet(),
      ).thenAnswer((_) async => chopperListResponse(<News>[]));
      EventBaseCreation? capturedEvent;
      when(
        () => scaffold.repository.calendarEventsPost(body: any(named: 'body')),
      ).thenAnswer((inv) async {
        capturedEvent = inv.namedArguments[#body] as EventBaseCreation;
        return chopperResponse(
          EventCompleteTicketUrl.empty().copyWith(
            id: 'e-new',
            name: 'Soirée de gala',
            associationId: 'a-1',
            decision: enums.Decision.pending,
          ),
        );
      });

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/add_edit_event',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 40);

      // Create mode: the association chip row shows, title field is empty.
      expect(find.text('Create an event'), findsOneWidget);
      expect(find.text('BDE'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);

      // Fill the form. Dates go through processDateBackWithHourMaybe, which
      // parses DateFormat.yMd(locale).add_Hm() — slash format, not ISO.
      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Soirée de gala',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Start date'),
        '10/10/2026 20:00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'End date'),
        '10/11/2026 02:00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Location'),
        'Amphi Marie Curie',
      );
      await settle(tester, frames: 6);

      // Submit: the real POST fires with the form values and the page pops
      // back to the feed with the success toast. The submit button sits
      // below the fold at this viewport — tester.tap silently drops taps on
      // off-screen widgets, so scroll it into view first.
      await tester.dragUntilVisible(
        find.text('Create an event'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await settle(tester, frames: 2);
      await tester.tap(find.text('Create an event'));
      await settle(tester, frames: 12);

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!.name, 'Soirée de gala');
      expect(capturedEvent!.location, 'Amphi Marie Curie');
      expect(capturedEvent!.associationId, 'a-1');
      expect(capturedEvent!.start.year, 2026);
      expect(find.text('Event added'), findsOneWidget);
      // Back on the feed main page.
      expect(find.text('No news available'), findsOneWidget);
      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
