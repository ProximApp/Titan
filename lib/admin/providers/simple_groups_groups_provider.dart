import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/map_provider.dart';

class SimpleGroupsGroupsNotifier extends MapNotifier<String, CoreGroupSimple> {
  @override
  Map<String, AsyncValue<List<CoreGroupSimple>>?> build() {
    final simpleGroups = ref.watch(allGroupListProvider);
    final loaded = simpleGroups.maybeWhen(
      data: (value) => value,
      orElse: () => <CoreGroupSimple>[],
    );
    return {for (final group in loaded) group.id: null};
  }
}

final simpleGroupsGroupsProvider =
    NotifierProvider<
      SimpleGroupsGroupsNotifier,
      Map<String, AsyncValue<List<CoreGroupSimple>>?>
    >(SimpleGroupsGroupsNotifier.new);
