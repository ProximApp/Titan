import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/booking/class/booking.dart';
import 'package:titan/booking/repositories/booking_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ManagerConfirmedBookingListProvider extends ListNotifier<Booking> {
  BookingRepository get bookingRepository =>
      ref.watch(bookingRepositoryProvider);

  @override
  AsyncValue<List<Booking>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Booking>>> loadConfirmedBookingForManager() async {
    return await loadList(
      () async => bookingRepository.getUserManageConfirmedBookingList(),
    );
  }

  Future<bool> addBooking(Booking booking) async {
    return await add((b) async => b, booking);
  }

  Future<bool> deleteBooking(Booking booking) async {
    return await delete(
      (_) async => true,
      (bookings, booking) =>
          bookings..removeWhere((element) => element.id == booking.id),
      booking.id,
      booking,
    );
  }
}

final managerConfirmedBookingListProvider =
    NotifierProvider<
      ManagerConfirmedBookingListProvider,
      AsyncValue<List<Booking>>
    >(() => ManagerConfirmedBookingListProvider());
