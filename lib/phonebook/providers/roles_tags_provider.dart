import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/phonebook/repositories/role_tags_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class RolesTagsNotifier extends ListNotifier<String> {
  RolesTagsRepository get rolesTagsRepository =>
      ref.watch(rolesTagsRepositoryProvider);

  @override
  AsyncValue<List<String>> build() {
    loadRolesTags();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<String>>> loadRolesTags() async {
    return loadList(rolesTagsRepository.getRolesTags);
  }
}

final rolesTagsProvider =
    NotifierProvider<RolesTagsNotifier, AsyncValue<List<String>>>(
      RolesTagsNotifier.new,
    );
