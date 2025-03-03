import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class RoomNotifier extends Notifier<RoomComplete> {
  @override
  RoomComplete build() {
    return EmptyModels.empty<RoomComplete>();
  }

  void setRoom(RoomComplete room) {
    state = room;
  }
}

final roomProvider = NotifierProvider<RoomNotifier, RoomComplete>(
  RoomNotifier.new,
);
