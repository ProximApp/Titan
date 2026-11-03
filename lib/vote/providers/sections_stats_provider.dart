import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/map_provider.dart';
import 'package:titan/vote/providers/sections_provider.dart';

class SectionsStatsNotifier extends MapNotifier<SectionComplete, int> {
  @override
  Map<SectionComplete, AsyncValue<List<int>>?> build() {
    final sections = ref.watch(sectionsProvider);
    final loaded = sections.maybeWhen(
      data: (value) => value,
      orElse: () => <SectionComplete>[],
    );
    return {for (final section in loaded) section: null};
  }
}

final sectionsStatsProvider =
    NotifierProvider<
      SectionsStatsNotifier,
      Map<SectionComplete, AsyncValue<List<int>>?>
    >(SectionsStatsNotifier.new);
