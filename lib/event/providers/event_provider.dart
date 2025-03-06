import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

class EventNotifier extends Notifier<EventComplete> {
  @override
  EventComplete build() {
    return EventComplete.fromJson({});
  }

  void setEvent(EventComplete event) {
    state = event;
  }

  void setRoom(String location) {
    state = state.copyWith(location: location);
  }
}

final eventProvider = NotifierProvider<EventNotifier, EventComplete>(
  EventNotifier.new,
);
