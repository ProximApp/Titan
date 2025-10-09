import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/user/class/simple_users.dart';

class StructureManagerProvider extends Notifier<SimpleUser> {
  @override
  SimpleUser build() {
    return SimpleUser.empty();
  }

  void setUser(SimpleUser user) {
    state = user;
  }
}

final structureManagerProvider =
    NotifierProvider<StructureManagerProvider, SimpleUser>(
      () => StructureManagerProvider(),
    );
