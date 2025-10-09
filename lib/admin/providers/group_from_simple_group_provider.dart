import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/group.dart';
import 'package:titan/tools/providers/single_map_provider.dart';

class GroupFromSimpleGroupNotifier extends SingleMapNotifier<String, Group> {
  @override
  Map<String, AsyncValue<Group>?> build() {
    return {};
  }
}

final groupFromSimpleGroupProvider =
    NotifierProvider<
      GroupFromSimpleGroupNotifier,
      Map<String, AsyncValue<Group>?>
    >(() => GroupFromSimpleGroupNotifier());
