import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/event/providers/event_provider.dart';
import 'package:titan/event/ui/components/event_ui.dart';
import 'package:titan/event/ui/pages/main_page/main_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/card_layout.dart';
import 'package:titan/tools/ui/layouts/column_refresher.dart';
import 'package:titan/tools/ui/widgets/admin_button.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';
import '../event_test_doubles.dart';

/// Page-level coverage for `EventMainPage` — a 0%-covered file before this
/// test. `EventRouter` is NOT registered in `AppRouter`, so there is no
/// `/event` deep link to boot (see the add_edit test's NOTE): the page is
/// mounted directly.
///
/// The QR.to taps (add tile, card info icon, Edit button) are driven
/// against qlevar's own test hook: `QR.settings.mockRoute` makes every
/// navigation resolve to a throwaway route, so the callbacks — setEvent +
/// navigation — run to completion and the destination is recorded.
void main() {
  late IntegrationScaffold scaffold;
  late RecordingRouteMock mock;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    mock = RecordingRouteMock();
    QR.settings.mockRoute = mock;
  });

  tearDown(() => QR.settings.mockRoute = null);

  final now = DateTime.now();

  final started = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-started',
    name: 'Kermesse en cours',
    location: 'Cour',
    start: now.subtract(const Duration(hours: 1)),
    end: now.add(const Duration(hours: 3)),
  );
  final soon = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-soon',
    name: 'Soirée Kino',
    location: 'Amphi Darwin',
    // Three lines: the card preview joins the first two and appends '...'.
    description: 'Deux films\nune discussion\net une troisième ligne',
    start: now.add(const Duration(days: 2, hours: 10)),
    end: now.add(const Duration(days: 2, hours: 12)),
  );
  final marche = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-marche',
    name: 'Marché de Noël',
    location: 'Place du cloître',
    start: now.add(const Duration(days: 1, hours: 15)),
    end: now.add(const Duration(days: 1, hours: 17)),
  );
  final expired = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-expired',
    name: 'Vieille fête',
    start: now.subtract(const Duration(days: 10)),
    end: now.subtract(const Duration(days: 5)),
  );

  void stubConfirmed(List<EventCompleteTicketUrl> events) {
    when(() => scaffold.repository.calendarEventsConfirmedGet())
        .thenAnswer((_) async => chopperListResponse(events));
  }

  testWidgets('an empty confirmed list shows the no-event label', (
    tester,
  ) async {
    stubConfirmed([]);
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'u-1'),
      userId: 'u-1',
    );
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const EventMainPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 6);

    expect(find.text('No event'), findsOneWidget);
    expect(find.text('My events'), findsNothing);
    // The add tile is the page's only CardLayout.
    expect(find.byType(CardLayout), findsOneWidget);
    // No admin_calendar group: the admin shortcut stays hidden.
    expect(find.byType(AdminButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an admin sees their events, drives the QR taps, deletes one and refreshes',
    (tester) async {
      stubConfirmed([started, soon, expired, marche]);
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          id: 'u-1',
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: 'b0357687-2211-410a-9e2a-144519eeaafa',
              name: 'admin_calendar',
            ),
          ],
        ),
        userId: 'u-1',
      );
      addTearDown(container.dispose);

      when(
        () => scaffold.repository.calendarEventsEventIdDelete(
          eventId: any(named: 'eventId'),
        ),
      ).thenAnswer((_) async => chopperResponse(true));

      await scaffold.pumpWidgetApp(
        tester,
        const EventMainPage(),
        container,
        // Deliberately shorter than the four-card list, but within the
        // ListView's build window (viewport + cacheExtent): the Cupertino
        // refresh control only arms from an overflown scrollable, and all
        // four cards must still be built for the count below.
        surface: const ui.Size(900, 1000),
      );
      await settle(tester, frames: 6);

      expect(find.text('My events'), findsOneWidget);
      expect(find.byType(EventUi), findsNWidgets(4));
      expect(find.byType(AdminButton), findsOneWidget);
      // The multi-line description preview truncates with '...'.
      expect(find.text('Deux films\nune discussion...'), findsOneWidget);
      expect(find.text('Amphi Darwin'), findsOneWidget);

      // Add tile: navigates to the standalone add_edit route.
      await tester.tap(find.byType(CardLayout));
      await settle(tester, frames: 2);
      expect(mock.navigated, contains('/event/add_edit'));

      // Card info icon: setEvent + QR.to('/event/detail').
      final infoIcon = find.descendant(
        of: find.byType(EventUi).first,
        matching: find.byType(HeroIcon),
      );
      await tester.tap(infoIcon);
      await settle(tester, frames: 2);
      expect(mock.navigated, contains('/event/detail'));

      // Edit button: setEvent + QR.to('/event/add_edit'). Qlevar skips a
      // push of the path it is already on (the add tile navigated there
      // first), so the observable effect is the event left in
      // eventProvider. Three member cards are on screen; the list sorts
      // newest-first, so the topmost card is the upcoming 'soon' event.
      await tester.tap(find.text('Edit').first);
      await settle(tester, frames: 2);
      expect(container.read(eventProvider).id, 'e-soon');

      // Delete flow: the confirmation dialog calls the real endpoint and
      // toasts the success message.
      await tester.tap(find.text('Delete').first);
      await settle(tester, frames: 4);
      expect(find.byType(CustomDialogBox), findsOneWidget);
      // CustomDialogBox's confirm button carries globalConfirm ('Confirm').
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 6);
      verify(
        () =>
            scaffold.repository.calendarEventsEventIdDelete(eventId: 'e-soon'),
      ).called(1);
      expect(find.text('Event deleted'), findsOneWidget);

      // Pull to refresh: the ColumnRefresher onRefresh closure, driven
      // with the pattern the purchases tests use (drag to the top edge,
      // then fling past the refresh threshold).
      await tester.drag(find.byType(ColumnRefresher), const Offset(0, 1500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.fling(
        find.byType(ColumnRefresher),
        const Offset(0, 300),
        1000,
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 8);
      verify(() => scaffold.repository.calendarEventsConfirmedGet())
          .called(greaterThan(1));

      // The delete toast schedules a 2.5s auto-dismiss timer; pump it out
      // so no timer outlives the disposed tree.
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );
}
