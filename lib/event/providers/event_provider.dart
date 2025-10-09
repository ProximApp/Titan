import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/event/class/event.dart';

class EventNotifier extends Notifier<Event> {
  @override
  Event build() {
    return Event.empty();
  }

  void setEvent(Event event) {
    state = event;
  }

  void setRoom(String location) {
    state = state.copyWith(location: location);
  }
}

final eventProvider = NotifierProvider<EventNotifier, Event>(EventNotifier.new);
