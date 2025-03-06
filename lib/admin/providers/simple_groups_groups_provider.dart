import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/group.dart';
import 'package:titan/admin/providers/group_list_provider.dart';
import 'package:titan/tools/providers/map_provider.dart';

class SimpleGroupsGroupsNotifier extends MapNotifier<String, Group> {
  
  @override
  Map<String, AsyncValue<List<InvalidType>>?> build() {
      final simpleGroups = ref.watch(allGroupListProvider);
      simpleGroups.whenData((value) {
        loadTList(value.map((e) => e.id).toList());
      });
    return state;
  }
}

final simpleGroupsGroupsProvider =
    NotifierProvider<
      SimpleGroupsGroupsNotifier,
      Map<String, AsyncValue<List<Group>>?>
    >(SimpleGroupsGroupsNotifier.new);
