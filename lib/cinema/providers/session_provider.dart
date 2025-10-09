import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/cinema/class/session.dart';

class SessionNotifier extends Notifier<Session> {
  @override
  Session build() {
    return Session.empty();
  }

  void setSession(Session event) {
    state = event;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);
