import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/booking/class/booking.dart';
import 'package:titan/booking/repositories/booking_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class UserBookingListProvider extends ListNotifier<Booking> {
  BookingRepository get bookingRepository =>
      ref.watch(bookingRepositoryProvider);

  @override
  AsyncValue<List<Booking>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Booking>>> loadUserBookings() async {
    return await loadList(bookingRepository.getUserBookingList);
  }

  Future<bool> addBooking(Booking booking) async {
    return await add(bookingRepository.createBooking, booking);
  }

  Future<bool> updateBooking(Booking booking) async {
    return await update(
      bookingRepository.updateBooking,
      (bookings, booking) =>
          bookings..[bookings.indexWhere((b) => b.id == booking.id)] = booking,
      booking,
    );
  }

  Future<bool> deleteBooking(Booking booking) async {
    return await delete(
      bookingRepository.deleteBooking,
      (bookings, booking) => bookings..removeWhere((i) => i.id == booking.id),
      booking.id,
      booking,
    );
  }
}

final userBookingListProvider =
    NotifierProvider<UserBookingListProvider, AsyncValue<List<Booking>>>(
      UserBookingListProvider.new,
    );
