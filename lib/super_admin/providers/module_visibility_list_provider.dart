import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class ModuleVisibilityListNotifier extends ListNotifierAPI<ModuleVisibility> {
  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<ModuleVisibility>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<ModuleVisibility>>> loadModuleVisibility() async {
    return await loadList(repository.moduleVisibilityGet);
  }

  Future<bool> addGroupToModule(
    ModuleVisibility moduleVisibility,
    String allowedGroupId,
  ) async {
    return await update(
      () => repository.moduleVisibilityPost(
        body: ModuleVisibilityCreate(
          root: moduleVisibility.root,
          allowedGroupId: allowedGroupId,
        ),
      ),
      (moduleVisibility) => moduleVisibility.root,
      moduleVisibility,
    );
  }

  Future<bool> deleteGroupAccessForModule(
    ModuleVisibility moduleVisibility,
    String allowedGroupId,
  ) async {
    return await update(
      () => repository.moduleVisibilityRootGroupsGroupIdDelete(
        root: moduleVisibility.root,
        groupId: allowedGroupId,
      ),
      (moduleVisibility) => moduleVisibility.root,
      moduleVisibility,
    );
  }

  Future<bool> addAccountTypeToModule(
    ModuleVisibility moduleVisibility,
    AccountType allowedAccountType,
  ) async {
    return await update(
      () async => repository.moduleVisibilityPost(
        body: ModuleVisibilityCreate(
          root: moduleVisibility.root,
          allowedAccountType: allowedAccountType,
        ),
      ),
      (moduleVisibility) => moduleVisibility.root,
      moduleVisibility,
    );
  }

  Future<bool> deleteAccountTypeAccessForModule(
    ModuleVisibility moduleVisibility,
    AccountType allowedAccountType,
  ) async {
    return await update(
      () async => repository.moduleVisibilityRootAccountTypesAccountTypeDelete(
        root: moduleVisibility.root,
        accountType: allowedAccountType,
      ),
      (moduleVisibility) => moduleVisibility.root,
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
    >(ModuleVisibilityListNotifier.new);
