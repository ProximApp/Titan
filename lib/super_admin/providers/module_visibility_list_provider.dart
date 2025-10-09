import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/super_admin/class/module_visibility.dart';
import 'package:titan/super_admin/repositories/module_visibility_repository.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ModuleVisibilityListNotifier extends ListNotifier<ModuleVisibility> {
  ModuleVisibilityRepository repository = ModuleVisibilityRepository();

  @override
  AsyncValue<List<ModuleVisibility>> build() {
    final token = ref.watch(tokenProvider);
    repository.setToken(token);
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<ModuleVisibility>>> loadModuleVisibility() async {
    return await loadList(repository.getModuleVisibilityList);
  }

  Future<bool> addGroupToModule(
    ModuleVisibility moduleVisibility,
    String allowedGroupId,
  ) async {
    return await update(
      (moduleVisibility) async =>
          repository.addGroupToModule(moduleVisibility.root, allowedGroupId),
      (list, moduleVisibility) => list
        ..[list.indexWhere((m) => m.root == moduleVisibility.root)] =
            moduleVisibility,
      moduleVisibility,
    );
  }

  Future<bool> deleteGroupAccessForModule(
    ModuleVisibility moduleVisibility,
    String allowedGroupId,
  ) async {
    return await update(
      (moduleVisibility) async => repository.deleteGroupAccessForModule(
        moduleVisibility.root,
        allowedGroupId,
      ),
      (list, moduleVisibility) => list
        ..[list.indexWhere((m) => m.root == moduleVisibility.root)] =
            moduleVisibility,
      moduleVisibility,
    );
  }

  Future<bool> addAccountTypeToModule(
    ModuleVisibility moduleVisibility,
    String allowedAccountType,
  ) async {
    return await update(
      (moduleVisibility) async => repository.addAccountTypeToModule(
        moduleVisibility.root,
        allowedAccountType,
      ),
      (list, moduleVisibility) => list
        ..[list.indexWhere((m) => m.root == moduleVisibility.root)] =
            moduleVisibility,
      moduleVisibility,
    );
  }

  Future<bool> deleteAccountTypeAccessForModule(
    ModuleVisibility moduleVisibility,
    String allowedAccountType,
  ) async {
    return await update(
      (moduleVisibility) async => repository.deleteAccountTypeAccessForModule(
        moduleVisibility.root,
        allowedAccountType,
      ),
      (list, moduleVisibility) => list
        ..[list.indexWhere((m) => m.root == moduleVisibility.root)] =
            moduleVisibility,
      moduleVisibility,
    );
  }

  void setState(List<ModuleVisibility> modules) {
    state = AsyncValue.data(modules);
  }
}

final moduleVisibilityListProvider =
    NotifierProvider<
      ModuleVisibilityListNotifier,
      AsyncValue<List<ModuleVisibility>>
    >(() => ModuleVisibilityListNotifier());
