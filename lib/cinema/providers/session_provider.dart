import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class SessionNotifier extends Notifier<CineSessionComplete> {
  @override
  CineSessionComplete build() {
    return EmptyModels.empty<CineSessionComplete>();
  }

  void setSession(CineSessionComplete event) {
    state = event;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, CineSessionComplete>(
  SessionNotifier.new,
);
