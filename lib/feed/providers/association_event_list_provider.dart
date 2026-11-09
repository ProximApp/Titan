import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class AssociationEventsListNotifier
    extends ListNotifierAPI<EventCompleteTicketUrl> {
  Openapi get eventsRepository => ref.watch(repositoryProvider);
  AsyncValue<List<EventCompleteTicketUrl>> allNews = const AsyncValue.loading();

  @override
  AsyncValue<List<EventCompleteTicketUrl>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<EventCompleteTicketUrl>>> loadAssociationEventList(
    String associationId,
  ) async {
    return allNews = await loadList(
      () => eventsRepository.calendarEventsAssociationsAssociationIdGet(
        associationId: associationId,
      ),
    );
  }

  Future<bool> updateEvent(EventCompleteTicketUrl event) async {
    return await update(
      () => eventsRepository.calendarEventsEventIdPatch(
        eventId: event.id,
        body: EventEdit(
          name: event.name,
          start: event.start,
          end: event.end,
          allDay: event.allDay,
          location: event.location,
          description: event.description,
          recurrenceRule: event.recurrenceRule,
          ticketUrl: event.ticketUrl,
          ticketUrlOpening: event.ticketUrlOpening,
          ticketEventId: event.ticketEventId,
          notification: event.notification,
        ),
      ),
      (event) => event.id,
      event,
    );
  }

  Future<bool> deleteEvent(EventCompleteTicketUrl event) async {
    // `delete`, not `update`: the DELETE endpoint answers with an empty body,
    // and updating the list in place would put the event back at its own
    // index — the card stayed on screen after a successful deletion.
    return await delete(
      () => eventsRepository.calendarEventsEventIdDelete(eventId: event.id),
      (event) => event.id,
      event.id,
    );
  }
}

final associationEventsListProvider =
    NotifierProvider<
      AssociationEventsListNotifier,
      AsyncValue<List<EventCompleteTicketUrl>>
    >(AssociationEventsListNotifier.new);
