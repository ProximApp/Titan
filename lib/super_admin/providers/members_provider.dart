import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/user/class/simple_users.dart';

class MembersNotifier extends Notifier<List<SimpleUser>> {
  @override
  List<SimpleUser> build() {
    return const [];
  }

  void add(SimpleUser user) {
    state = state.sublist(0)..add(user);
  }

  void remove(SimpleUser user) {
    state = state.where((element) => element.id != user.id).toList();
  }
}

final membersProvider = NotifierProvider<MembersNotifier, List<SimpleUser>>(
  () => MembersNotifier(),
);
