import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/providers/map_provider.dart';
import 'package:titan/vote/class/contender.dart';
import 'package:titan/vote/class/section.dart';

class SectionContender extends MapNotifier<Section, Contender> {}

final sectionContenderProvider =
    NotifierProvider<
      SectionContender,
      Map<Section, AsyncValue<List<Contender>>?>
    >(() => SectionContender());
