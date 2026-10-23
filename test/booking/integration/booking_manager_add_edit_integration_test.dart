import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/booking/providers/booking_provider.dart';
import 'package:titan/booking/providers/manager_booking_list_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../booking_fixtures.dart';

/// The manager edit branch of add_edit_booking_page, reached on the gated
/// route `/booking/manager/add_edit` (AdminMiddleware lets isManagerProvider
/// through via makeContainer's myManagerRoles). Nothing else runs here: the
/// success path calls QR.back(), and a deep link after that pop lands on the
/// manager parent instead of the child (kept in its own file for it).
///
/// What this covers and the plain-user file cannot:
/// * `applicant:` / `applicantId:` keep the BOOKING's own values on the
///   isManagerPage=true branch (lines 449-452);
/// * the save routes through managerBookingListProvider.updateBooking
///   (lines 456-459);
/// * the seed's 00:00 → 23:59 times flip the all-day derive on mount
///   (lines 57-60).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the manager edit branch saves for the manager\'s own '
      'applicant', (tester) async {
    final container = scaffold.makeContainer(
      // The manager-route gate (isManagerProvider) derives from this.
      myManagerRoles: [
        Manager.empty().copyWith(id: 'mgr-1', name: 'Amphi', groupId: 'grp-1'),
      ],
    );
    final seed = BookingReturnApplicant.empty().copyWith(
      id: 'b-m1',
      reason: 'Weekly meeting',
      entity: 'BDE',
      // 00:00 → 23:59 on one day: the mount-time all-day derive (57-60).
      start: DateTime(2026, 10, 20, 0, 0),
      end: DateTime(2026, 10, 20, 23, 59),
      creation: DateTime(2026, 10, 1),
      key: false,
      roomId: 'room-1',
      room: RoomComplete.empty().copyWith(id: 'room-1', name: 'Amphi A'),
      applicantId: 'applicant-7',
      applicant: Applicant.empty(),
      recurrenceRule: '',
    );
    stubBookingEndpoints(scaffold, managed: [seed]);
    when(
      () => scaffold.repository.bookingBookingsBookingIdPatch(
        bookingId: any(named: 'bookingId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => chopperResponseVoid());
    container.read(bookingProvider.notifier).setBooking(seed);
    // Materialise the manager list state before the save: updateBooking's
    // handleState refuses to PATCH while the notifier is still loading.
    container.read(managerBookingListProvider);

    await pumpAddEdit(
      scaffold,
      tester,
      container,
      path: '/booking/manager/add_edit',
    );

    // All-day derive ran off the seeded 00:00/23:59 times.
    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes[2].value, isTrue, reason: 'all-day derived on mount');
    expect(boxes[1].value, isFalse, reason: 'no recurrence rule stored');

    // entity + reason, then the room chip (both scroll positions differ on
    // this taller, all-day form).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Club des élèves');
    await tester.enterText(fields.at(1), 'Weekly meeting');
    await tester.ensureVisible(find.text('Amphi A'));
    await tester.pump();
    await tester.tap(find.text('Amphi A'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Edit'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Edit'));
    await tester.tap(find.text('Edit'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // isManagerPage routes through managerBookingListProvider (456-459) and
    // keeps the booking's OWN applicant/applicantId (449-452).
    final captured = verify(
      () => scaffold.repository.bookingBookingsBookingIdPatch(
        bookingId: captureAny(named: 'bookingId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'b-m1');
    expect(find.text('Booking edited'), findsOneWidget);
    // Drain the success toast it schedules around the pop.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
