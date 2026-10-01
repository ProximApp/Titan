import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The booking add-edit page (`/booking/add_edit`, 184 executable lines —
/// the booking module's biggest file), reached on the plain user branch
/// (no manager/admin gate on this route).
///
/// The page reads the room list (bookingRoomsGet), keeps its target in
/// bookingProvider, and posts through UserBookingListProvider.addBooking
/// (bookingBookingsPost). Field order: entity, motif, note, start, end —
/// the room comes from the chip row at the top.
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

  void stubBookingEndpoints() {
    when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse<RoomComplete>([
        RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
        RoomComplete.empty().copyWith(id: 'room-2', name: 'Salle B'),
      ]),
    );
    // UserBookingListProvider.build() loads the user's bookings; its data
    // state is what allows add() to run. The success path reloads three
    // more lists (user, confirmed, manager ones).
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

  testWidgets('the create form renders fields, chips and the room row', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    stubBookingEndpoints();

    await pumpAddEdit(tester, container);

    expect(find.text('Add booking'), findsOneWidget);
    expect(find.text('For whom?'), findsOneWidget);
    expect(find.text('Reason'), findsOneWidget);
    // canBeEmpty renders the localized "{text} (Optional)" label.
    expect(find.text('Note (Optional)'), findsOneWidget);
    expect(find.text('Key needed'), findsOneWidget);
    expect(find.text('Recurrence'), findsOneWidget);
    expect(find.text('All day'), findsOneWidget);
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('End date'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    // The room chips render from the repository.
    expect(find.text('Amphi A'), findsOneWidget);
    expect(find.text('Salle B'), findsOneWidget);
  });

  testWidgets('saving without a room chip shows the invalid-room toast', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    stubBookingEndpoints();

    await pumpAddEdit(tester, container);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Club des élèves');
    await tester.enterText(fields.at(1), 'Weekly meeting');
    await tester.enterText(fields.at(3), '15/01/2026 18:00');
    await tester.enterText(fields.at(4), '15/01/2026 20:00');

    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Add'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Invalid room'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.bookingBookingsPost(body: any(named: 'body')),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  // Runs LAST: its success path calls QR.back(), and a test that leaves the
  // router wedged breaks the next deep link in the same file.
  testWidgets('a filled form books a room and toasts success', (tester) async {
    final container = scaffold.makeContainer();
    stubBookingEndpoints();
    when(
      () => scaffold.repository.bookingBookingsPost(body: any(named: 'body')),
    ).thenAnswer((_) async => chopperResponse(BookingReturn.empty()));

    await pumpAddEdit(tester, container);

    // Select the room chip, then fill the text fields.
    await tester.tap(find.text('Amphi A'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Club des élèves');
    await tester.enterText(fields.at(1), 'Weekly meeting');
    await tester.enterText(fields.at(2), 'Bring badges');
    await tester.enterText(fields.at(3), '15/01/2026 18:00');
    await tester.enterText(fields.at(4), '15/01/2026 20:00');

    // Release the field focus so the tap reaches the button.
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Add'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    final captured =
        verify(
              () => scaffold.repository.bookingBookingsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.last
            as BookingBase;
    expect(captured.reason, 'Weekly meeting');
    expect(captured.roomId, 'room-1');
    // Ledger #18 fixed: toBookingBase() carries entity and note into the
    // created booking. The page sends the RRULE as an EMPTY STRING for
    // non-recurring bookings (its non-recurrent default), not null.
    expect(captured.entity, 'Club des élèves');
    expect(captured.note, 'Bring badges');
    expect(captured.recurrenceRule, isEmpty);
    expect(find.text('Request added'), findsOneWidget);
    // Drain the success toast (autoClose 2500ms + 400ms animation).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
