import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/providers/booking_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// Residual add-edit flows the other two files do not reach
/// (booking_add_edit_integration_test covers the plain CREATE happy path,
/// booking_add_edit_recurrence_integration_test the edit-mode recurrence
/// machinery from a NON-recurring preset):
///
/// * the all-day CREATE guard — append 00:00/23:59, then end-before-start;
/// * the create-path ERROR toast when bookingBookingsPost fails;
/// * EDIT mode with an RRULE STORED on the booking: the interval and
///   recurrence-end controllers parse the rule on mount (page lines 84-91,
///   the true branch neither other file takes).
///
/// The manager branch lives in booking_manager_add_edit_integration_test:
/// a QR.back() here would wedge that file's nested deep link. Success paths
/// call QR.back(), so the RRULE round-trip runs LAST.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpAddEdit(
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

  void stubBookingEndpoints({List<BookingReturn> mine = const []}) {
    when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse<RoomComplete>([
        RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
        RoomComplete.empty().copyWith(id: 'room-2', name: 'Salle B'),
      ]),
    );
    when(() => scaffold.repository.bookingBookingsUsersMeGet())
        .thenAnswer((_) async => chopperListResponse<BookingReturn>(mine));
    when(() => scaffold.repository.bookingBookingsConfirmedGet()).thenAnswer(
      (_) async => chopperListResponse<BookingReturnSimpleApplicant>(
        <BookingReturnSimpleApplicant>[],
      ),
    );
    when(() => scaffold.repository.bookingBookingsUsersMeManageGet())
        .thenAnswer(
          (_) async => chopperListResponse<BookingReturnApplicant>(
            <BookingReturnApplicant>[],
          ),
        );
  }

  /// Shared preamble: entity/reason/note plus the room chip.
  Future<void> fillCommonFields(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Club des élèves');
    await tester.enterText(fields.at(1), 'Weekly meeting');
    await tester.ensureVisible(find.text('Amphi A'));
    await tester.pump();
    await tester.tap(find.text('Amphi A'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> tapSubmit(WidgetTester tester, String label) async {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text(label),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  testWidgets('an all-day form whose end precedes the start refuses to save', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    stubBookingEndpoints();

    await pumpAddEdit(tester, container);

    // Ticking "All day" wipes the date texts first, so toggle before typing.
    await tester.ensureVisible(find.byType(Checkbox).at(2));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(2));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value, isTrue);

    await fillCommonFields(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(3), '16/01/2026');
    await tester.enterText(fields.at(4), '15/01/2026');

    await tapSubmit(tester, 'Add');

    // The all-day branch appends 00:00/23:59 first, then the end-before-start
    // guard fires and the POST never happens.
    expect(find.text('Invalid dates'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.bookingBookingsPost(body: any(named: 'body')),
    );
    await drainToast(tester);
  });

  testWidgets('a failed create POST toasts the adding error', (tester) async {
    final container = scaffold.makeContainer();
    stubBookingEndpoints();
    when(
      () => scaffold.repository.bookingBookingsPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async =>
          chopper.Response<BookingReturn>(http.Response('body', 500), null),
    );

    await pumpAddEdit(tester, container);

    await fillCommonFields(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(3), '15/01/2026 18:00');
    await tester.enterText(fields.at(4), '15/01/2026 20:00');

    await tapSubmit(tester, 'Add');

    // add() treats the non-2xx as a failure and the page toasts
    // bookingAddingError (line 504, the create-error branch).
    expect(find.text('Error while adding'), findsOneWidget);
    verify(
      () => scaffold.repository.bookingBookingsPost(body: any(named: 'body')),
    ).called(1);
    await drainToast(tester);
  });

  /// Opens every plain-mode date field's picker and confirms the default:
  /// the onTap closure bodies are coverage lines of their own, and the
  /// all-day switch flips which picker each field launches.
  testWidgets('each plain date field launches its date and time pickers', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    stubBookingEndpoints();

    await pumpAddEdit(tester, container);

    Future<void> confirmDatePicker() async {
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('OK'),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    Future<void> confirmTimePicker() async {
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.text('OK'),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    Future<void> openField(int index) async {
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.at(index));
      await tester.pump();
      await tester.tap(fields.at(index));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    // Non-all-day start: getFullDate = date dialog, then time dialog.
    await openField(3);
    await confirmDatePicker();
    await confirmTimePicker();
    expect(find.byType(TextFormField).at(3).evaluate().isNotEmpty, isTrue);
    var texts = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(texts[3].controller!.text, isNotEmpty);
    expect(texts[4].controller!.text, isEmpty);

    // Non-all-day end: same pair (lines 310/312).
    await openField(4);
    await confirmDatePicker();
    await confirmTimePicker();
    texts = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(texts[4].controller!.text, isNotEmpty);

    // All-day flips both fields to the date-only picker (lines 301/311).
    await tester.ensureVisible(find.byType(Checkbox).at(2));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(2));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await openField(3);
    await confirmDatePicker();
    expect(find.byType(TimePickerDialog), findsNothing);
    await openField(4);
    await confirmDatePicker();
    expect(find.byType(TimePickerDialog), findsNothing);

    await drainToast(tester);
  });

  /// Recurrence mode swaps in hour-only fields plus the end-date picker
  /// (page lines 268-269, 277-278, 288-289 are those onTap closures).
  testWidgets('the recurrence fields launch hour and date pickers', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    stubBookingEndpoints();

    await pumpAddEdit(tester, container);

    await tester.ensureVisible(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(1));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    Future<void> openField(int index) async {
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.at(index));
      await tester.pump();
      await tester.tap(fields.at(index));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    // Start hour → time picker only.
    await openField(4);
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.byType(DatePickerDialog), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.text('OK'),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // End hour → time picker only.
    await openField(5);
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.text('OK'),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // Recurrence end date → date picker only.
    await openField(6);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.byType(TimePickerDialog), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('OK'),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    final texts = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(texts[4].controller!.text, isNotEmpty);
    expect(texts[5].controller!.text, isNotEmpty);
    expect(texts[6].controller!.text, isNotEmpty);

    await drainToast(tester);
  });

  // Runs LAST: its success path calls QR.back().
  testWidgets('editing a recurring booking re-reads the stored RRULE and '
      'patches it', (tester) async {
    const rule =
        'FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=2027-06-01T00:00:00Z;INTERVAL=3';
    final container = scaffold.makeContainer();
    stubBookingEndpoints(
      mine: [
        BookingReturn.empty().copyWith(
          id: 'b-9',
          reason: 'Weekly meeting',
          entity: 'BDE',
          start: DateTime(2026, 12, 2, 10, 0),
          end: DateTime(2026, 12, 2, 11, 0),
          creation: DateTime(2026, 10, 1),
          roomId: 'room-1',
          room: RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
          recurrenceRule: rule,
        ),
      ],
    );
    when(
      () => scaffold.repository.bookingBookingsBookingIdPatch(
        bookingId: any(named: 'bookingId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());

    // The page builds from bookingProvider (what a list-card tap seeds);
    // id b-9 marks this as edit mode.
    container
        .read(bookingProvider.notifier)
        .setBooking(
          BookingReturnApplicant.empty().copyWith(
            id: 'b-9',
            reason: 'Weekly meeting',
            entity: 'BDE',
            start: DateTime(2026, 12, 2, 10, 0),
            end: DateTime(2026, 12, 2, 11, 0),
            creation: DateTime(2026, 10, 1),
            key: false,
            roomId: 'room-1',
            room: RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
            applicantId: 'user-1',
            applicant: Applicant.empty(),
            recurrenceRule: rule,
          ),
        );

    await pumpAddEdit(tester, container);

    // Mount-time prefill: hour fields from the stored start/end, interval
    // and recurrence-end parsed straight out of the RRULE (lines 84-91).
    expect(find.text('Edit a booking'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('2027'), findsOneWidget);

    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes[1].value, isTrue, reason: 'Recurrence derived from BYDAY');
    expect(boxes[2].value, isFalse, reason: 'not an all-day booking');
    // Day rows: Key, Recurrence, All day, then Monday..Sunday.
    expect(boxes[3].value, isFalse, reason: 'selectedDays starts empty');

    // The stored rule does not repopulate the day ticks — ticking Monday is
    // what puts BYDAY back into the regenerated rule.
    await tester.ensureVisible(find.byType(Checkbox).at(3));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(3));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(tester.widget<Checkbox>(find.byType(Checkbox).at(3)).value, isTrue);

    await tapSubmit(tester, 'Edit');

    final captured = verify(
      () => scaffold.repository.bookingBookingsBookingIdPatch(
        bookingId: captureAny(named: 'bookingId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'b-9');
    final body = captured[1] as BookingEdit;
    // Regenerated from the prefilled interval + the ticked Monday.
    expect(body.recurrenceRule, contains('FREQ=WEEKLY'));
    expect(body.recurrenceRule, contains('BYDAY=MO'));
    expect(body.recurrenceRule, contains('INTERVAL=3'));
    expect(find.text('Booking edited'), findsOneWidget);
    await drainToast(tester);
  });
}
