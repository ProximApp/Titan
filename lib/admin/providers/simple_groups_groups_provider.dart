import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/group.dart';
import 'package:titan/tools/providers/map_provider.dart';

class SimpleGroupsGroupsNotifier extends MapNotifier<String, Group> {
  SimpleGroupsGroupsNotifier();
}

final simpleGroupsGroupsProvider =
    NotifierProvider<
      SimpleGroupsGroupsNotifier,
      Map<String, AsyncValue<List<Group>>?>
    >(() => SimpleGroupsGroupsNotifier());
