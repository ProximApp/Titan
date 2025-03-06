import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/simple_group.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class UserListNotifier extends ListNotifierAPI<CoreUserSimple> {
  Openapi get userListRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<CoreUserSimple>> build() {
      clear();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<CoreUserSimple>>> filterUsers(
    String query, {
    List<SimpleGroup>? includedGroups,
    List<SimpleGroup>? excludedGroups,
    List<AccountType>? includedAccountTypes,
    List<AccountType>? excludedAccountTypes,
  }) async {
    return await loadList(
      () async => userListRepository.usersSearchGet(
        query: query,
        includedGroups: includedGroups?.map((e) => e.id).toList(),
        excludedGroups: excludedGroups?.map((e) => e.id).toList(),
      ),
    );
  }

  Future clear() async {
    state = const AsyncValue.data([]);
  }
}

final userList =
    NotifierProvider<UserListNotifier, AsyncValue<List<CoreUserSimple>>>(
      UserListNotifier.new,
    );
