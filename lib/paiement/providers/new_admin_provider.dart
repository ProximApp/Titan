import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/user/class/simple_users.dart';

class NewAdminNotifier extends Notifier<SimpleUser> {
  @override
  SimpleUser build() => SimpleUser.empty();

  void updateNewAdmin(SimpleUser newAdmin) {
    state = newAdmin;
  }

  void resetNewAdmin() {
    state = SimpleUser.empty();
  }
}

final newAdminProvider = NotifierProvider<NewAdminNotifier, SimpleUser>(
  NewAdminNotifier.new,
);
