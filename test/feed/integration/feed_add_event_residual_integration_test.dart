import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The create-mode residuals of add_event_page that the happy-path file
/// skips: the whole submit validation chain (no association, the SG
/// date/link pairing, the existing-ticketing requirement, end-before-start),
/// the association chip selection, the "use an existing ticketing" switch
/// with its manage-permission gate and dropdown round-trip, and the
/// existing-ticketing create payload. One deep-link boot; every interaction
/// is preceded by an explicit scroll (off-screen taps are dropped and the
/// page is taller than the viewport).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Brings [finder] into the viewport: a negative dy scrolls down the
  /// page, a positive one back up.
  Future<void> dragTo(WidgetTester tester, Finder finder, double dy) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(SingleChildScrollView).last,
      Offset(0, dy),
    );
    await settle(tester, frames: 2);
  }

  Future<void> submit(WidgetTester tester) async {
    await dragTo(tester, find.text('Create an event'), -600);
    await tester.tap(find.text('Create an event'));
    await settle(tester, frames: 10);
  }

  testWidgets(
    'create-mode validation chain, ticketing picker and existing-ticketing round-trip',
    (tester) async {
      final container = scaffold.makeContainer(
        user: models.CoreUser.empty().copyWith(id: 'me'),
        myAssociations: [
          models.Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
          models.Association(name: 'BDA', groupId: 'g-1', id: 'a-2'),
        ],
        // The ticketing gate: a store belonging to a-1 whose seller (me)
        // can manage events. a-2 has no store → gate closed there.
        myStores: [
          models.UserStore.empty().copyWith(
            id: 'store-1',
            name: 'BDE store',
            associationId: 'a-1',
          ),
        ],
        storeSellers: {
          'store-1': [
            Seller.empty().copyWith(userId: 'me', canManageEvents: true),
          ],
        },
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(
        () => scaffold.repository.feedNewsGet(),
      ).thenAnswer((_) async => chopperListResponse(<News>[]));
      when(
        () => scaffold.repository.ticketsAdminAssociationAssociationIdEventsGet(
          associationId: any(named: 'associationId'),
        ),
      ).thenAnswer(
        (_) async => chopperListResponse<EventSimple>([
          EventSimple.empty().copyWith(id: 'te-1', name: 'Gala ticketing'),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/feed/add_edit_event',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 40);

      // Two associations → nothing is pre-selected.
      expect(find.text('Create an event'), findsOneWidget);

      // 1. Submit without an association → the association toast.
      await submit(tester);
      expect(find.text('Please select an association'), findsOneWidget);
      await scaffold.drainToast(tester);

      // 2. Select the BDA chip (scroll back up first). With no store for
      // a-2 the ticketing switch is disabled and carries the permission
      // subtitle.
      await dragTo(tester, find.text('BDA'), 600);
      await tester.tap(find.text('BDA'));
      await settle(tester, frames: 6);
      await dragTo(tester, find.text('Use an existing ticketing'), -400);
      expect(find.text('Use an existing ticketing'), findsOneWidget);
      expect(
        find.text(
          'The "Manage ticket events" permission in MyEmpay is required to use this option.',
        ),
        findsOneWidget,
      );
      final gatedSwitch = tester.widget<SwitchListTile>(
        find
            .ancestor(
              of: find.text('Use an existing ticketing'),
              matching: find.byType(SwitchListTile),
            )
            .first,
      );
      expect(gatedSwitch.onChanged, isNull);
      expect(find.text('Select a ticketing'), findsNothing);

      // 3. SG external link without a SG date → the date toast. (Both SG
      // labels render with the "(Optional)" suffix from canBeEmpty.)
      await dragTo(tester, find.text('SG External link (Optional)'), -400);
      await tester.enterText(
        find.widgetWithText(TextField, 'SG External link (Optional)'),
        'https://billetterie.example/gala',
      );
      await settle(tester, frames: 4);
      await submit(tester);
      expect(find.text('Please provide a SG date'), findsOneWidget);
      await scaffold.drainToast(tester);

      // 4. SG date without a link → the link toast. The SG date is a
      // read-only DateEntry (AbsorbPointer'd field with a tap handler):
      // set it through the real date+time pickers.
      await dragTo(tester, find.text('SG External link (Optional)'), -400);
      await tester.enterText(
        find.widgetWithText(TextField, 'SG External link (Optional)'),
        '',
      );
      await settle(tester, frames: 4);
      await dragTo(tester, find.text('SG Date (Optional)'), -400);
      await tester.tap(find.text('SG Date (Optional)'));
      await settle(tester, frames: 8);
      await tester.tap(find.text('OK').first);
      await settle(tester, frames: 8);
      await tester.tap(find.text('OK').first);
      await settle(tester, frames: 8);
      await submit(tester);
      expect(find.text('Please provide a SG external link'), findsOneWidget);
      await scaffold.drainToast(tester);

      // 5. Back on BDE the gate opens: the switch toggles and loads the
      // association's ticket events into the dropdown.
      await dragTo(tester, find.text('BDE'), 600);
      await tester.tap(find.text('BDE'));
      await settle(tester, frames: 6);
      await dragTo(tester, find.text('Use an existing ticketing'), -400);
      await tester.tap(find.text('Use an existing ticketing'));
      await settle(tester, frames: 10);
      expect(find.text('Select a ticketing'), findsOneWidget);
      // The external rows disappeared with the toggle.
      expect(find.text('SG External link (Optional)'), findsNothing);

      // 6. Existing ticketing without a selection → its own toast.
      await submit(tester);
      expect(find.text('Please select an existing ticketing'), findsOneWidget);
      await scaffold.drainToast(tester);

      // 7. Select the ticketing, then submit with end < start → dates toast.
      await tester.tap(find.text('Select a ticketing'));
      await settle(tester, frames: 10);
      await tester.tap(find.text('Gala ticketing').last);
      await settle(tester, frames: 8);
      await dragTo(tester, find.widgetWithText(TextField, 'Title'), 600);
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
        '10/09/2026 20:00',
      );
      await settle(tester, frames: 4);
      await submit(tester);
      expect(find.text('End date must be after start date'), findsOneWidget);
      await scaffold.drainToast(tester);

      // 8. Fix the dates and submit: the event carries the selected
      // ticketing id, no external link, no SG date.
      await dragTo(tester, find.widgetWithText(TextField, 'End date'), 600);
      await tester.enterText(
        find.widgetWithText(TextField, 'End date'),
        '10/11/2026 02:00',
      );
      await settle(tester, frames: 4);
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
      await submit(tester);
      expect(capturedEvent, isNotNull);
      expect(capturedEvent!.name, 'Soirée de gala');
      expect(capturedEvent!.ticketEventId, 'te-1');
      expect(capturedEvent!.ticketUrl, isNull);
      expect(capturedEvent!.ticketUrlOpening, isNull);
      expect(capturedEvent!.associationId, 'a-1');
      expect(find.text('Event added'), findsOneWidget);
      expect(find.text('No news available'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
