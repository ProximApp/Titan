import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:titan/admin/providers/is_admin_provider.dart';
import 'package:titan/advert/providers/advert_list_provider.dart';
import 'package:titan/advert/providers/advert_posters_provider.dart';
import 'package:titan/advert/providers/selected_association_provider.dart';
import 'package:titan/advert/ui/components/special_action_button.dart';
import 'package:titan/advert/ui/pages/advert.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/advert/ui/components/association_bar.dart';
import 'package:titan/advert/ui/pages/main_page/advert_card.dart';
import 'package:titan/feed/providers/is_user_a_member_of_an_association.dart';
import 'package:titan/navigation/providers/navbar_visibility_provider.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/tools/ui/builders/async_child.dart';
import 'package:qlevar_router/qlevar_router.dart';

class AdvertMainPage extends HookConsumerWidget {
  const AdvertMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advertList = ref.watch(advertListProvider);
    final advertListNotifier = ref.watch(advertListProvider.notifier);
    final advertPostersNotifier = ref.watch(advertPostersProvider.notifier);
    final selected = ref.watch(selectedAssociationProvider);
    final selectedNotifier = ref.watch(selectedAssociationProvider.notifier);
    final isAdvertAdmin = ref.watch(isUserAMemberOfAnAssociationProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final pathForwarding = ref.watch(pathForwardingProvider);
    final advertId = pathForwarding.queryParameters?['advertId'];
    final navbarVisibilityNotifier = ref.watch(
      navbarVisibilityProvider.notifier,
    );

    final itemScrollController = ItemScrollController();
    final itemPositionsListener = useMemoized(
      () => ItemPositionsListener.create(),
    );

    return AdvertTemplate(
      child: RefreshIndicator(
        color: ColorConstants.main,
        onRefresh: () async {
          await advertListNotifier.loadAdverts();
          advertPostersNotifier.resetTData();
        },
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: const AssociationBar(
                    useUserAssociations: false,
                    multipleSelect: true,
                  ),
                ),

                if (isAdmin || isAdvertAdmin) ...[
                  SizedBox(width: 5),
                  Container(
                    width: 2,
                    height: 60,
                    color: ColorConstants.secondary,
                  ),
                  SizedBox(width: 5),
                  SpecialActionButton(
                    onTap: () {
                      selectedNotifier.clearAssociation();
                      QR.to(AdvertRouter.root + AdvertRouter.admin);
                    },
                    icon: HeroIcon(
                      HeroIcons.userGroup,
                      color: ColorConstants.background,
                    ),
                    name: "Admin",
                  ),
                  SizedBox(width: 10),
                ],
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: AsyncChild(
                value: advertList,
                builder: (context, adverts) {
                  return HookBuilder(
                    builder: (context) {
                      final sortedAdvertData = adverts
                          .sortedBy((element) => element.date)
                          .reversed;
                      final filteredSortedAdvertData = sortedAdvertData
                          .where(
                            (advert) =>
                                selected
                                    .where((e) => advert.associationId == e.id)
                                    .isNotEmpty ||
                                selected.isEmpty,
                          )
                          .toList();

                      final advertIndex = filteredSortedAdvertData.indexWhere(
                        (advert) => advert.id == advertId,
                      );
                      final lastFirstIndex = useRef<int?>(null);
                      if (advertIndex != -1) {
                        useEffect(() {
                          Future.microtask(() async {
                            if (itemScrollController.isAttached) {
                              await itemScrollController.scrollTo(
                                index: advertIndex,
                                duration: const Duration(milliseconds: 300),
                              );
                              navbarVisibilityNotifier.show();
                            }
                          });
                          void listener() {
                            final positions =
                                itemPositionsListener.itemPositions.value;
                            if (positions.isEmpty) return;
                            final visiblePositions = positions.where(
                              (p) =>
                                  p.itemLeadingEdge >= 0 &&
                                  p.itemLeadingEdge <= 1,
                            );

                            if (visiblePositions.isEmpty) return;

                            final firstVisible = visiblePositions.fold<int>(
                              999999,
                              (prev, e) => e.index < prev ? e.index : prev,
                            );

                            final lastIndex = lastFirstIndex.value;

                            if (lastIndex != null) {
                              if (firstVisible > lastIndex) {
                                navbarVisibilityNotifier.hide();
                              } else if (firstVisible < lastIndex) {
                                navbarVisibilityNotifier.show();
                              }
                            }

                            lastFirstIndex.value = firstVisible;
                          }

                          itemPositionsListener.itemPositions.addListener(
                            listener,
                          );
                          return () => itemPositionsListener.itemPositions
                              .removeListener(listener);
                        }, []);
                      }
                      return ScrollablePositionedList.builder(
                        itemCount: filteredSortedAdvertData.length,
                        itemBuilder: (context, index) =>
                            AdvertCard(advert: filteredSortedAdvertData[index]),
                        itemScrollController: itemScrollController,
                        itemPositionsListener: itemPositionsListener,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
