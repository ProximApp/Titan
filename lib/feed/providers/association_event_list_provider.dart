import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/class/event.dart';
import 'package:titan/feed/repositories/event_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class AssociationEventsListNotifier extends ListNotifier<Event> {
  EventRepository get eventsRepository => ref.watch(eventRepositoryProvider);
  AsyncValue<List<Event>> allNews = const AsyncValue.loading();

  @override
  AsyncValue<List<Event>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Event>>> loadAssociationEventList(
    String associationId,
  ) async {
    return allNews = await loadList(
      () => eventsRepository.getAssociationEventList(associationId),
    );
  }

  Future<bool> updateEvent(Event event) async {
    return await update(
      (event) => eventsRepository.updateEvent(event),
      (eventList, event) =>
          eventList..[eventList.indexWhere((d) => d.id == event.id)] = event,
      event,
    );
  }

  Future<bool> deleteEvent(Event event) async {
    return await update(
      (event) => eventsRepository.deleteEvent(event.id),
      (eventList, event) => eventList..removeWhere((d) => d.id == event.id),
      event,
    );
  }
}

final associationEventsListProvider =
    NotifierProvider<AssociationEventsListNotifier, AsyncValue<List<Event>>>(
      AssociationEventsListNotifier.new,
    );
