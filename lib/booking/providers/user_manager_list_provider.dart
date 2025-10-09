import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/booking/class/manager.dart';
import 'package:titan/booking/repositories/manager_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class UserManagerListNotifier extends ListNotifier<Manager> {
  ManagerRepository get managerRepository =>
      ref.watch(managerRepositoryProvider);

  @override
  AsyncValue<List<Manager>> build() {
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
