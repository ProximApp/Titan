import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/map_provider.dart';
import 'package:titan/vote/providers/list_list_provider.dart';
import 'package:titan/vote/providers/sections_provider.dart';

class SectionList extends MapNotifier<SectionComplete, ListReturn> {
  @override
  Map<SectionComplete, AsyncValue<List<ListReturn>>?> build() {
    final sections = ref.watch(sectionList);
    final lists = ref.watch(listListProvider);
    final loaded = lists.maybeWhen(
      data: (value) => value,
      orElse: () => <ListReturn>[],
    );
    return {
      for (final section in sections)
        section: AsyncValue.data(
          loaded.where((element) => element.section.id == section.id).toList(),
        ),
    };
  }
}

final sectionListProvider =
    NotifierProvider<
      SectionList,
      Map<SectionComplete, AsyncValue<List<ListReturn>>?>
    >(SectionList.new);
