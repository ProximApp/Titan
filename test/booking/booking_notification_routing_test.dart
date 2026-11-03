import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/notification_service.dart';
import 'package:titan/booking/providers/confirmed_booking_list_provider.dart';
import 'package:titan/booking/providers/manager_booking_list_provider.dart';
import 'package:titan/booking/providers/user_booking_list_provider.dart';
import 'package:titan/booking/router.dart';

/// The booking notification routing table: which push keys the module claims,
/// where they land, and which providers must refresh. Never evaluated by a
/// test, so a renamed key or a wrong landing route was invisible.
void main() {
  test('routes the two booking keys to their audiences', () {
    expect(bookingProviders.keys.toList()..sort(), ['bookings', 'userBooking']);

    final user = bookingProviders['userBooking']!;
    final admin = bookingProviders['bookings']!;

    // A borrower lands on the booking module, an admin on its admin page.
    expect(user.item1, BookingRouter.root);
    expect(admin.item1, BookingRouter.root + BookingRouter.admin);

    // Each audience refreshes only its own lists.
    expect(user.item2, contains(userBookingListProvider));
    expect(user.item2, contains(confirmedBookingListProvider));
    expect(user.item2, isNot(contains(managerBookingListProvider)));

    expect(admin.item2, contains(managerBookingListProvider));
    expect(admin.item2, isNot(contains(userBookingListProvider)));
  });
}
