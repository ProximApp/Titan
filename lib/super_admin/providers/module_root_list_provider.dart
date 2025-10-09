import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/super_admin/repositories/module_visibility_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';
import 'package:titan/user/providers/user_provider.dart';

class ModuleListNotifier extends ListNotifier<String> {
  ModuleVisibilityRepository get repository =>
      ref.watch(moduleVisibilityRepositoryProvider);

  @override
  AsyncValue<List<String>> build() {
    final userProvider = ref.watch(asyncUserProvider);
    userProvider.maybeWhen(
      data: (data) => tokenExpireWrapperAuth(ref, () async {
        await loadMyModuleRoots();
      }),
      orElse: () {},
    );
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<String>>> loadMyModuleRoots() async {
    return await loadList(repository.getAccessibleModule);
  }
}

final moduleRootListProvider =
    NotifierProvider<ModuleListNotifier, AsyncValue<List<String>>>(
      ModuleListNotifier.new,
    );
