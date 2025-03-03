import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class BookingNotifier extends Notifier<BookingReturnApplicant> {
  @override
  BookingReturnApplicant build() {
    return EmptyModels.empty<BookingReturnApplicant>();
  }

  void setBooking(BookingReturnApplicant booking) {
    state = booking;
  }
}

final bookingProvider =
    NotifierProvider<BookingNotifier, BookingReturnApplicant>(
      BookingNotifier.new,
    );
