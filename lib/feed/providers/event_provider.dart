import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/class/event.dart';
import 'package:titan/feed/repositories/event_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class EventNotifier extends SingleNotifier<Event> {
  EventRepository get eventRepository => ref.watch(eventRepositoryProvider);

  @override
  AsyncValue<Event> build() {
    fakeLoad();
    return const AsyncValue.loading();
  }

  Future<Event> addEvent(Event event) async {
    return await eventRepository.createEvent(event);
  }

  void fakeLoad() {
    state = AsyncValue.data(Event.empty());
  }

  void setEvent(Event event) {
    state = AsyncValue.data(event);
  }
}

final eventProvider = NotifierProvider<EventNotifier, AsyncValue<Event>>(
  EventNotifier.new,
);
