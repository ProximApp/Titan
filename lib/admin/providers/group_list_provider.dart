import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/repositories/group_repository.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class GroupListNotifier extends ListNotifier<SimpleGroup> {
  GroupRepository get groupRepository => ref.watch(groupRepositoryProvider);

  @override
  AsyncValue<List<SimpleGroup>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<SimpleGroup>>> loadGroups() async {
    return await loadList(groupRepository.getGroupList);
  }

  Future<AsyncValue<List<SimpleGroup>>> loadGroupsFromUser(CoreUser user) async {
    return await loadList(() async => user.groups);
  }

  Future<bool> createGroup(SimpleGroup group) async {
    return await add(groupRepository.createGroup, group);
  }

  Future<bool> updateGroup(SimpleGroup group) async {
    return await update(
      groupRepository.updateGroup,
      (groups, group) =>
          groups..[groups.indexWhere((g) => g.id == group.id)] = group,
      group,
    );
  }

  Future<bool> deleteGroup(SimpleGroup group) async {
    return await delete(
      groupRepository.deleteGroup,
      (groups, group) => groups..removeWhere((i) => i.id == group.id),
      group.id,
      group,
    );
  }

  void setGroup(SimpleGroup group) {
    state.whenData((d) {
      if (d.indexWhere((g) => g.id == group.id) == -1) return;
      state = AsyncValue.data(
        d..[d.indexWhere((g) => g.id == group.id)] = group,
      );
    });
  }
}

final allGroupListProvider =
    NotifierProvider<GroupListNotifier, AsyncValue<List<SimpleGroup>>>(
      GroupListNotifier.new,
    );

final userGroupListNotifier =
    NotifierProvider<GroupListNotifier, AsyncValue<List<SimpleGroup>>>(
      GroupListNotifier.new,
    );
