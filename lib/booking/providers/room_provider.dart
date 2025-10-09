import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/service/class/room.dart';

class RoomNotifier extends Notifier<Room> {
  @override
  Room build() {
    return Room.empty();
  }

  void setRoom(Room room) {
    state = room;
  }
}

final roomProvider = NotifierProvider<RoomNotifier, Room>(RoomNotifier.new);
