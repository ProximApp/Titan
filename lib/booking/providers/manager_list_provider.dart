import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/booking/class/manager.dart';
import 'package:titan/booking/repositories/manager_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ManagerListNotifier extends ListNotifier<Manager> {
  ManagerRepository get repository => ref.watch(managerRepositoryProvider);

  @override
  AsyncValue<List<Manager>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Manager>>> loadManagers() async {
    return await loadList(repository.getManagerList);
  }

  Future<bool> addManager(Manager manager) async {
    return await add(repository.createManager, manager);
  }

  Future<bool> updateManager(Manager manager) async {
    return await update(
      repository.updateManager,
      (managers, manager) =>
          managers..[managers.indexWhere((m) => m.id == manager.id)] = manager,
      manager,
    );
  }

  Future<bool> deleteManager(Manager manager) async {
    return await delete(
      repository.deleteManager,
      (managers, manager) => managers..removeWhere((m) => m.id == manager.id),
      manager.id,
      manager,
    );
  }
}

final managerListProvider =
    NotifierProvider<ManagerListNotifier, AsyncValue<List<Manager>>>(
      ManagerListNotifier.new,
    );
