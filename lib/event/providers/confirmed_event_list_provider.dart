import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/event/class/event.dart';
import 'package:titan/event/repositories/event_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ConfirmedEventListProvider extends ListNotifier<Event> {
  EventRepository get eventRepository => ref.watch(eventRepositoryProvider);

  @override
  AsyncValue<List<Event>> build() {
    loadConfirmedEvent();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Event>>> loadConfirmedEvent() async {
    return await loadList(eventRepository.getConfirmedEventList);
  }

  Future<bool> addEvent(Event booking) async {
    return await add((b) async => b, booking);
  }

  Future<bool> deleteEvent(Event booking) async {
    return await delete(
      (_) async => true,
      (bookings, booking) =>
          bookings..removeWhere((element) => element.id == booking.id),
      booking.id,
      booking,
    );
  }
}

final confirmedEventListProvider =
    NotifierProvider<ConfirmedEventListProvider, AsyncValue<List<Event>>>(
      ConfirmedEventListProvider.new,
    );
