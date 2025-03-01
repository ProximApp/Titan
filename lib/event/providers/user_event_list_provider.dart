import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class EventEventListProvider extends ListNotifierAPI<EventComplete> {
  Openapi get eventRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<EventComplete>> build() {
    final userId = ref.watch(idProvider);
    tokenExpireWrapperAuth(ref, () async {
      userId.whenData((value) async {
        await loadConfirmedEvent();
      });
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<EventComplete>>> loadConfirmedEvent() async {
    return await loadList(eventRepository.calendarEventsConfirmedGet);
  }

  Future<bool> addEvent(EventBaseCreation event) async {
    return await add(
      () => eventRepository.calendarEventsPost(body: event),
      event,
    );
  }

  Future<bool> updateEvent(EventComplete event) async {
    return await update(
      () => eventRepository.calendarEventsEventIdPatch(
        eventId: event.id,
        body: EventEdit(
          name: event.name,
          start: event.start,
          end: event.end,
          allDay: event.allDay,
          location: event.location,
          description: event.description,
          recurrenceRule: event.recurrenceRule,
        ),
      ),
      (event) => event.id,
      event,
    );
  }

  Future<bool> deleteEvent(EventComplete event) async {
    return await delete(
      () => eventRepository.calendarEventsEventIdDelete(eventId: event.id),
      (event) => event.id,
      event.id,
    );
  }
}

final eventEventListProvider =
    NotifierProvider<EventEventListProvider, AsyncValue<List<EventComplete>>>(
      EventEventListProvider.new,
    );
