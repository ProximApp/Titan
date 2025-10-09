import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/booking/class/manager.dart';
import 'package:titan/booking/repositories/manager_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class UserManagerListNotifier extends ListNotifier<Manager> {
  final ManagerRepository managerRepository = ManagerRepository();

  @override
  AsyncValue<List<Manager>> build() {
    final token = ref.watch(tokenProvider);
    managerRepository.setToken(token);
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Manager>>> loadManagers() async {
    return await loadList(managerRepository.getUserManagerList);
  }
}

final userManagerListProvider =
    NotifierProvider<UserManagerListNotifier, AsyncValue<List<Manager>>>(
      UserManagerListNotifier.new,
    );
