import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/simple_group.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';
import 'package:titan/user/class/simple_users.dart';
import 'package:titan/user/repositories/user_list_repository.dart';

class UserListNotifier extends ListNotifier<SimpleUser> {
  late final UserListRepository userListRepository;

  @override
  AsyncValue<List<SimpleUser>> build() {
    userListRepository = ref.watch(userListRepositoryProvider);
    tokenExpireWrapperAuth(ref, () async {
      clear();
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<SimpleUser>>> filterUsers(
    String query, {
    List<SimpleGroup>? includeGroup,
    List<SimpleGroup>? excludeGroup,
  }) async {
    return await loadList(
      () async => userListRepository.searchUser(
        query,
        includeId: includeGroup?.map((e) => e.id).toList(),
        excludeId: excludeGroup?.map((e) => e.id).toList(),
      ),
    );
  }

  Future clear() async {
    state = const AsyncValue.data([]);
  }
}

final userList =
    NotifierProvider<UserListNotifier, AsyncValue<List<SimpleUser>>>(
      UserListNotifier.new,
    );
