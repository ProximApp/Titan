import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';

class ModuleListNotifier extends ListNotifierAPI<String> {
  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<String>> build() {
    final userProvider = ref.watch(asyncUserProvider);
    userProvider.maybeWhen(
      data: (data) => {loadMyModuleRoots()},
      orElse: () {},
    );
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<String>>> loadMyModuleRoots() async {
    final response = await repository.permissionsListGet();
    if (!response.isSuccessful || response.body == null) {
      state = const AsyncValue.data(<String>[]);
      return state;
    }

    final allPermissions = response.body!;

    final moduleRoots = <String>{};
    for (final permission in allPermissions) {
      if (permission.contains('.access')) {
        final moduleRoot = permission.split('.').first;
        moduleRoots.add(moduleRoot);
      }
    }

    final moduleRootsList = moduleRoots.toList()..sort();
    state = AsyncValue.data(moduleRootsList);
    return state;
  }
}

final moduleRootListProvider =
    NotifierProvider<ModuleListNotifier, AsyncValue<List<String>>>(
      ModuleListNotifier.new,
    );
