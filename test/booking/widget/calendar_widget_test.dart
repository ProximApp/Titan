import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

import 'package:titan/booking/ui/calendar/calendar.dart';
import 'package:titan/booking/ui/calendar/calendar_dialog.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the booking `Calendar`: the appointment-tap
/// handler in BOTH its manager and plain branches (the dialog it opens is
/// covered on its own in calendar_dialog_widget_test.dart), the two
/// web-format week-navigation buttons, and the provider error fallback.
///
/// The tap callback is invoked directly instead of by pixel: syncfusion
/// paints appointments itself, so there is no widget to hit-test — the
/// details object is what the calendar hands the handler on a real tap.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  BookingReturnApplicant applicantBooking() =>
      BookingReturnApplicant.empty().copyWith(
        id: 'b-1',
        reason: 'Réunion',
        start: DateTime(2026, 10, 20, 14),
        end: DateTime(2026, 10, 20, 16),
        entity: 'BDE',
        room: RoomComplete.empty().copyWith(id: 'r-1', name: 'Amphi'),
        applicant: Applicant.empty().copyWith(
          id: 'a-1',
          name: 'Delaunay',
          firstname: 'Jean-Baptiste',
          email: 'jb@example.com',
        ),
      );

  /// Both calendar flavors load their list through the SAME endpoint
  /// (ManagerConfirmedBookingListProvider also calls
  /// bookingBookingsConfirmedGet).
  void stubConfirmed() {
    when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturnSimpleApplicant>(
        <BookingReturnSimpleApplicant>[],
      ),
    );
  }

  testWidgets('tapping an appointment opens the dialog on the user calendar', (
    tester,
  ) async {
    stubConfirmed();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const Calendar(isManagerPage: false),
      container,
    );
    await settle(tester);

    final calendar = tester.widget<sf.SfCalendar>(find.byType(sf.SfCalendar));
    calendar.onTap!(
      sf.CalendarTapDetails(
        <BookingReturnApplicant>[applicantBooking()],
        DateTime(2026, 10, 20),
        sf.CalendarElement.appointment,
        null,
      ),
    );
    await settle(tester);

    expect(find.byType(CalendarDialog), findsOneWidget);
    expect(find.textContaining('Amphi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an appointment opens the manager-flavored dialog', (
    tester,
  ) async {
    stubConfirmed();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const Calendar(isManagerPage: true),
      container,
    );
    await settle(tester);

    final calendar = tester.widget<sf.SfCalendar>(find.byType(sf.SfCalendar));
    // agenda, not appointment: the condition's first operand short-circuits
    // on appointment, so this side of the `||` needs the other hit for the
    // guard line itself to record coverage.
    calendar.onTap!(
      sf.CalendarTapDetails(
        <BookingReturnApplicant>[applicantBooking()],
        DateTime(2026, 10, 20),
        sf.CalendarElement.agenda,
        null,
      ),
    );
    await settle(tester);

    // isManager: true exposes the contact block the plain branch hides.
    expect(find.byType(CalendarDialog), findsOneWidget);
    expect(find.textContaining('jb@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed confirmed-list load renders the error fallback', (
    tester,
  ) async {
    when(() => scaffold.repository.bookingBookingsConfirmedGet())
        .thenThrow(Exception('confirmed down'));
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const Calendar(isManagerPage: false),
      container,
    );
    await settle(tester);

    // loadList funnels the failure into AsyncValue.error, which the widget
    // renders as the raw error string — no crash, no empty spinner forever.
    expect(find.textContaining('confirmed down'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide surface renders the forward/backward week controls', (
    tester,
  ) async {
    stubConfirmed();
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    // 1920 logical px at DPR 1 clears isWebFormatProvider's 500px safe-width
    // threshold, so both Positioned IconButtons mount.
    await scaffold.pumpWidgetApp(
      tester,
      const Calendar(isManagerPage: false),
      container,
      surface: const ui.Size(1920, 1080),
    );
    await settle(tester);

    final navButtons = find.byWidgetPredicate(
      (w) => w is IconButton && w.icon is HeroIcon,
    );
    expect(navButtons, findsNWidgets(2));

    // forward (right arrow, first in the Stack) then backward: both callbacks
    // call calendarController.forward!/backward!, which syncfusion only
    // assigns once the calendar view state has been built.
    await tester.tap(navButtons.at(0));
    await settle(tester, frames: 4);
    await tester.tap(navButtons.at(1));
    await settle(tester, frames: 4);
    expect(tester.takeException(), isNull);
  });
}
