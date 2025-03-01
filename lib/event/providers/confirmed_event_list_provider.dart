import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class ConfirmedEventListProvider extends ListNotifierAPI<EventComplete> {
  Openapi get eventRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<EventComplete>> build() {
    loadConfirmedEvent();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<EventComplete>>> loadConfirmedEvent() async {
    return await loadList(eventRepository.calendarEventsConfirmedGet);
  }

  Future<bool> addEvent(EventComplete booking) async {
    return await localAdd(booking);
  }

  Future<bool> deleteEvent(EventComplete booking) async {
    return await localDelete((booking) => booking.id, booking.id);
  }
}

final confirmedEventListProvider =
    NotifierProvider<
      ConfirmedEventListProvider,
      AsyncValue<List<EventComplete>>
    >(ConfirmedEventListProvider.new);
