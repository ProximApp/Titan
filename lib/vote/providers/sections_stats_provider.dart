import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/providers/map_provider.dart';
import 'package:titan/vote/class/section.dart';

class SectionsStatsNotifier extends MapNotifier<Section, int> {
  SectionsStatsNotifier();
}

final sectionsStatsProvider =
    NotifierProvider<
      SectionsStatsNotifier,
      Map<Section, AsyncValue<List<int>>?>
    >(() => SectionsStatsNotifier());
