import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/booking/providers/booking_provider.dart';

import '../../shared/app_scaffold.dart';

/// add_edit_booking_page's RESIDUAL uncovered paths — the existing
/// booking_add_edit_integration_test.dart covers the CREATE flow (render,
/// invalid-room toast, plain add). Everything here runs in EDIT mode with a
/// booking pre-seeded into bookingProvider (the state the my-bookings list
/// pushes before navigating) and exercises the recurrence machinery:
/// the Recurrence checkbox branch, week-day toggles, the interval/end-date
/// fields, the no-day-selected guard, and the RRULE round-trip through the
/// PATCH endpoint (create POST + the create-path field drops live in the
/// other file — nothing overlaps).
BookingReturnApplicant presetBooking() =>
    BookingReturnApplicant.empty().copyWith(
      id: 'bk-1',
      reason: 'Weekly meeting',
      entity: 'Club des élèves',
      note: 'Bring badges',
      start: DateTime(2026, 1, 15, 18),
      end: DateTime(2026, 1, 15, 20),
      key: true,
      room: models.RoomComplete.empty().copyWith(id: 'room-2', name: 'Salle B'),
      roomId: 'room-2',
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubBookingEndpoints() {
    when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse<models.RoomComplete>([
        models.RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
        models.RoomComplete.empty().copyWith(id: 'room-2', name: 'Salle B'),
      ]),
    );
    when(() => scaffold.repository.bookingBookingsUsersMeGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturn>(<BookingReturn>[]),
    );
    when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturnSimpleApplicant>(
        <BookingReturnSimpleApplicant>[],
      ),
    );
    when(
      () => scaffold.repository.bookingBookingsUsersMeManageGet(),
    ).thenAnswer(
      (_) async => chopperListResponse<BookingReturnApplicant>(
        <BookingReturnApplicant>[],
      ),
    );
  }

  /// Pumps the edit form with the preset booking already in bookingProvider
  /// (the page derives its edit state from that provider, not the route).
  Future<void> pumpEditForm(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/booking/add_edit',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Edit'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Edit'));
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('Edit'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('edit mode pre-fills and the recurrence branch reshapes the '
      'form', (tester) async {
    stubBookingEndpoints();
    final container = scaffold.makeContainer();
    container.read(bookingProvider.notifier).setBooking(presetBooking());

    await pumpEditForm(tester, container);

    // Edit mode: header and button label flip.
    expect(find.text('Edit a booking'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    // The pre-filled controllers carry the seeded booking (probed by
    // controller value: the label texts alone are ambiguous).
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, 'Club des élèves');
    expect(fields[1].controller!.text, 'Weekly meeting');
    expect(fields[2].controller!.text, 'Bring badges');
    // The en locale renders yMd as M/d/yyyy.
    expect(fields[3].controller!.text, '1/15/2026 18:00');
    expect(fields[4].controller!.text, '1/15/2026 20:00');
    expect(find.textContaining('Salle B'), findsOneWidget);

    // Toggling Recurrence swaps the date entries for the weekly machinery
    // and CLEARS the date controllers. Tap the CHECKBOX: the row's
    // GestureDetector writes the notifier directly and skips the onChanged
    // hook, so the clear would not happen.
    await tester.tap(find.byType(Checkbox).at(1));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Recurrence days'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    // 'Interval' renders twice: the section text and the field label.
    expect(find.text('Interval'), findsNWidgets(2));
    expect(find.text('Every'), findsOneWidget);
    expect(find.text('Weeks'), findsOneWidget);
    expect(find.text('Recurrence end date'), findsOneWidget);
    final cleared = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    // Tree order after the swap: entity, motif, note, interval, start
    // hour, end hour, recurrence end date. The date controllers were
    // cleared by the toggle; the interval field carries its default '1'.
    expect(cleared[3].controller!.text, '1');
    expect(cleared[4].controller!.text, '');
    expect(cleared[5].controller!.text, '');

    // Toggling a week day shows its checkbox state (the week-day rows are
    // plain GestureDetectors with no such split — text taps work there).
    await tester.tap(find.text('Monday'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    final checkboxes = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .toList();
    // 3 checked: Key needed + Recurrence (both toggled) + Monday. The
    // all-day checkbox is still unchecked.
    expect(checkboxes.where((c) => c.value == true).length, 3);
  });

  testWidgets('a recurrence without any day is refused before the call', (
    tester,
  ) async {
    stubBookingEndpoints();
    final container = scaffold.makeContainer();
    container.read(bookingProvider.notifier).setBooking(presetBooking());

    await pumpEditForm(tester, container);

    await tester.tap(find.byType(Checkbox).at(1));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    // Fill the now-cleared hour fields so the form validators pass and the
    // guard under test (no day selected) is the one that fires. Tree order:
    // interval at(3) keeps its default '1', start hour at(4), end hour
    // at(5), recurrence end date at(6).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(4), '18:00');
    await tester.enterText(fields.at(5), '20:00');
    await tester.enterText(fields.at(6), '12/31/2027');

    await tapSave(tester);

    expect(find.text('No day selected'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.bookingBookingsBookingIdPatch(
        bookingId: any(named: 'bookingId'),
        body: any(named: 'body'),
      ),
    );
    verifyNever(
      () => scaffold.repository.bookingBookingsPost(body: any(named: 'body')),
    );
    await scaffold.drainToast(tester);
  });

  testWidgets('the recurrence form round-trips an RRULE through the PATCH', (
    tester,
  ) async {
    stubBookingEndpoints();
    when(
      () => scaffold.repository.bookingBookingsBookingIdPatch(
        bookingId: any(named: 'bookingId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    // The success path refetches the booking lists.
    when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturnSimpleApplicant>(
        <BookingReturnSimpleApplicant>[],
      ),
    );
    final container = scaffold.makeContainer();
    container.read(bookingProvider.notifier).setBooking(presetBooking());

    await pumpEditForm(tester, container);

    await tester.tap(find.byType(Checkbox).at(1));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    // Tree order after the swap: entity, motif, note, interval, start
    // hour, end hour, recurrence end date (probed in the render test).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(3), '2');
    await tester.enterText(fields.at(4), '18:00');
    await tester.enterText(fields.at(5), '20:00');
    await tester.enterText(fields.at(6), '12/31/2027');
    // The week-day row sits below the fold after the field edits.
    await tester.ensureVisible(find.text('Monday'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Monday'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    await tapSave(tester);

    // The EDIT path PATCHes the existing booking; the create POST is never
    // touched.
    final captured =
        verify(
              () => scaffold.repository.bookingBookingsBookingIdPatch(
                bookingId: 'bk-1',
                body: captureAny(named: 'body'),
              ),
            ).captured.single
            as BookingEdit;
    expect(captured.reason, 'Weekly meeting');
    // The edit path converts the built booking with toBookingReturn(),
    // which carries note/entity/recurrenceRule into the BookingEdit PATCH
    // body (ledger #27, fixed).
    expect(captured.note, 'Bring badges');
    expect(captured.entity, 'Club des élèves');
    // The generated RRULE carries the weekly Monday, the interval 2 and
    // the end date typed into the form.
    expect(captured.recurrenceRule, contains('BYDAY=MO'));
    expect(captured.recurrenceRule, contains('INTERVAL=2'));
    // The local end date is serialized in UTC by syncfusion (12/31 00:00
    // +01:00 → UNTIL=20271230T230000Z), so only the year is pinned.
    expect(captured.recurrenceRule, contains('UNTIL=2027'));
    // Success: the page pops (QR.back) and reloads the booking lists. The
    // 'Booking edited' toast renders on the PREVIOUS route after the pop,
    // so it is not observable from here — the user-list reload is the
    // observable effect. Drain the toast timer it schedules.
    verify(
      () => scaffold.repository.bookingBookingsUsersMeGet(),
    ).called(greaterThanOrEqualTo(1));
    await scaffold.drainToast(tester);
  });

  testWidgets('cleared date fields fail validation with the fields toast', (
    tester,
  ) async {
    stubBookingEndpoints();
    final container = scaffold.makeContainer();
    container.read(bookingProvider.notifier).setBooking(presetBooking());

    await pumpEditForm(tester, container);

    // Toggling All day on and back off (via the CHECKBOX, whose onChanged
    // hook clears the date controllers each time) leaves the dates empty,
    // so the form validators fail.
    await tester.tap(find.byType(Checkbox).at(2));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.tap(find.byType(Checkbox).at(2));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tapSave(tester);

    // The DateEntry fields carry a canBeEmpty=false validator whose
    // message is the localized "Date required".
    expect(find.text('Date required'), findsNWidgets(2));
    expect(find.text('Incorrect or missing fields'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.bookingBookingsBookingIdPatch(
        bookingId: any(named: 'bookingId'),
        body: any(named: 'body'),
      ),
    );
    await scaffold.drainToast(tester);
  });
}
