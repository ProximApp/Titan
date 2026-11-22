import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/centralisation/providers/centralisation_section_provider.dart';
import 'package:titan/centralisation/providers/favorites_providers.dart';
import 'package:titan/centralisation/ui/centralisation.dart';

import 'package:titan/centralisation/ui/pages/liked_card.dart';
import 'package:titan/centralisation/ui/pages/section_list.dart';
import 'package:titan/tools/ui/builders/async_child.dart';

class CentralisationMainPage extends HookConsumerWidget {
  const CentralisationMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(sectionProvider);
    final sections = ref.watch(sectionProvider);
    final favoritesName = ref.watch(favoritesNameProvider);
    final favoritesNameNotifier = ref.read(favoritesNameProvider.notifier);
    final favorites = sections.maybeWhen(
      data: (sections) {
        final modules = sections
            .map((section) => section.moduleList)
            .expand((element) => element);
        // Favourites are persisted (SharedPreferences) while the module list
        // comes from the server, so a renamed or removed module leaves a
        // name nothing resolves any more. The bare `firstWhere` that used to
        // run here threw `Bad state: No element` out of build and killed
        // every section on the page; an unresolvable name is now dropped and
        // the strip simply keeps the favourites that still exist.
        final moduleByName = {
          for (final module in modules) module.name: module,
        };
        return [
          for (final name in favoritesName)
            if (moduleByName.containsKey(name)) moduleByName[name]!,
        ];
      },
      orElse: () => [],
    );

    return CentralisationTemplate(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AsyncChild(
          value: section,
          builder: (context, sections) => Column(
            children: [
              if (favorites.isNotEmpty)
                Container(
                  padding: const EdgeInsets.only(top: 15, bottom: 5),
                  height: 135,
                  child: ReorderableListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    proxyDecorator: (widget, _, animation) => Transform.scale(
                      scale: 1 + .05 * animation.value,
                      child: widget,
                    ),
                    header: const SizedBox(width: 15),
                    footer: const SizedBox(width: 15),
                    onReorderItem: favoritesNameNotifier.reorderFavorites,
                    children: favorites
                        .map(
                          (module) =>
                              LikedCard(module: module, key: Key(module.name)),
                        )
                        .toList(),
                  ),
                ),
              ...sections.map<Widget>(
                (section) => SectionList(section: section),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
