import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The all-day arm of `add_event_page`: with the "all day" box ticked the two
/// date rows must open the DAY-ONLY picker (`getOnlyDayDate`) instead of the
/// date+time pair, and toggling the box must clear what the other mode wrote
/// (an all-day event that kept its hours is the bug the checkbox callback was
/// introduced for). Same pass covers the notification box, whose `onChanged`
/// is a deliberate no-op because `CheckBoxEntry` owns the flip.
///
/// One deep-link boot, one journey: the screen is taller than the viewport, so
/// every off-screen target is scrolled into view first.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> dragTo(WidgetTester tester, Finder finder, double dy) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(SingleChildScrollView).last,
      Offset(0, dy),
    );
    await settle(tester, frames: 2);
  }

  String fieldText(WidgetTester tester, String label) => tester
      .widget<TextField>(find.widgetWithText(TextField, label))
      .controller!
      .text;

  testWidgets('all-day opens the day-only picker and clears the date rows', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(id: 'me'),
      // A single association is pre-selected, which is what keeps the SG rows
      // (they only render for a chosen association) on screen.
      myAssociations: [
        models.Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
      ],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.feedNewsGet())
        .thenAnswer((_) async => chopperListResponse(<News>[]));
    when(
      () => scaffold.repository.ticketsAdminAssociationAssociationIdEventsGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async => chopperListResponse<EventSimple>([]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/add_edit_event',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);
    expect(find.text('Create an event'), findsOneWidget);

    // Two checkboxes on this page: all-day first, notification second.
    expect(find.byType(Checkbox), findsNWidgets(2));

    // Tick "all day": the callback clears both date rows, because a day-only
    // event must not inherit hours typed for a timed one.
    await tester.tap(find.byType(Checkbox).first);
    await settle(tester, frames: 6);
    expect(fieldText(tester, 'Start date'), '');
    expect(fieldText(tester, 'End date'), '');

    // Start date in all-day mode: ONE picker (a day), so a single OK closes
    // it and the field carries no time component.
    await dragTo(tester, find.widgetWithText(TextField, 'Start date'), 600);
    await tester.tap(find.widgetWithText(TextField, 'Start date'));
    await settle(tester, frames: 8);
    await tester.tap(find.text('OK').first);
    await settle(tester, frames: 8);
    final allDayStart = fieldText(tester, 'Start date');
    expect(allDayStart, isNotEmpty);
    expect(
      allDayStart.contains(':'),
      isFalse,
      reason: 'the all-day picker must not write a time of day',
    );
    expect(
      find.text('OK'),
      findsNothing,
      reason: 'a day-only pick needs one OK, not the date+time pair',
    );

    // Same for the end date.
    await dragTo(tester, find.widgetWithText(TextField, 'End date'), 600);
    await tester.tap(find.widgetWithText(TextField, 'End date'));
    await settle(tester, frames: 8);
    await tester.tap(find.text('OK').first);
    await settle(tester, frames: 8);
    expect(fieldText(tester, 'End date').contains(':'), isFalse);

    // The notification box: its onChanged is intentionally empty (the entry
    // widget flips the notifier itself), so the value must still change.
    await dragTo(tester, find.byType(Checkbox).last, -400);
    final beforeNotification = tester
        .widget<Checkbox>(find.byType(Checkbox).last)
        .value;
    await tester.tap(find.byType(Checkbox).last);
    await settle(tester, frames: 4);
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox).last).value,
      !beforeNotification!,
    );
    expect(tester.takeException(), isNull);
  });
}
