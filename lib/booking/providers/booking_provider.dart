import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/booking/class/booking.dart';

class BookingNotifier extends Notifier<Booking> {
  @override
  Booking build() {
    return Booking.empty();
  }

  void setBooking(Booking booking) {
    state = booking;
  }
}

final bookingProvider = NotifierProvider<BookingNotifier, Booking>(
  BookingNotifier.new,
);
