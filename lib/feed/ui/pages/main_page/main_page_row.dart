import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/providers/my_association_list_provider.dart';
import 'package:titan/feed/class/news.dart';
import 'package:titan/feed/providers/association_event_list_provider.dart';
import 'package:titan/feed/providers/is_feed_admin_provider.dart';
import 'package:titan/feed/providers/is_user_a_member_of_an_association.dart';
import 'package:titan/feed/providers/news_list_provider.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/feed/ui/pages/main_page/filter_news.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/button.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';

class MainPageRow extends HookConsumerWidget {
  const MainPageRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizeWithContext = AppLocalizations.of(context)!;
    final newsListNotifier = ref.watch(newsListProvider.notifier);
    final isUserAMemberOfAnAssociation = ref.watch(
      isUserAMemberOfAnAssociationProvider,
    );
    final isFeedAdmin = ref.watch(isFeedAdminProvider);
    final associationEventsListNotifier = ref.watch(
      associationEventsListProvider.notifier,
    );
    final myAssociations = ref.watch(myAssociationListProvider);
    return Row(
      children: [
        Text(
          localizeWithContext.feedNews,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorConstants.title,
          ),
        ),
        Spacer(),
        IconButton(
          icon: HeroIcon(
            HeroIcons.adjustmentsHorizontal,
            color: ColorConstants.tertiary,
            size: 20,
          ),
          onPressed: () async {
            final syncNews = newsListNotifier.allNews.maybeWhen(
              orElse: () => <News>[],
              data: (loaded) => loaded,
            );
            final entities = syncNews.map((e) => e.entity).toSet().toList();
            final modules = syncNews.map((e) => e.module).toSet().toList();
            await showCustomBottomModal(
              modal: FilterNewsModal(entities: entities, modules: modules),
              context: context,
              ref: ref,
            );
          },
          splashRadius: 20,
        ),
        if (isUserAMemberOfAnAssociation || isFeedAdmin)
          CustomIconButton(
            icon: HeroIcon(
              !isFeedAdmin && isUserAMemberOfAnAssociation
                  ? HeroIcons.pencil
                  : HeroIcons.userGroup,
              color: ColorConstants.background,
            ),
            onPressed: () {
              if (isFeedAdmin && !isUserAMemberOfAnAssociation) {
                QR.to(FeedRouter.root + FeedRouter.eventHandling);
              } else {
                showCustomBottomModal(
                  modal: BottomModalTemplate(
                    title: localizeWithContext.feedAdmin,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Button(
                          text: localizeWithContext.feedCreateAnEvent,
                          onPressed: () {
                            Navigator.of(context).pop();
                            QR.to(FeedRouter.root + FeedRouter.addEditEvent);
                          },
                        ),
                        const SizedBox(height: 20),
                        Button(
                          text: localizeWithContext.feedManageAssociationEvents,
                          onPressed: () {
                            Navigator.of(context).pop();
                            associationEventsListNotifier
                                .loadAssociationEventList(
                                  myAssociations.first.id,
                                );
                            QR.to(
                              FeedRouter.root + FeedRouter.associationEvents,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        if (isFeedAdmin)
                          Button(
                            text: localizeWithContext.feedManageRequests,
                            onPressed: () {
                              Navigator.of(context).pop();
                              newsListNotifier.loadNewsList();
                              QR.to(FeedRouter.root + FeedRouter.eventHandling);
                            },
                          ),
                      ],
                    ),
                  ),
                  context: context,
                  ref: ref,
                );
              }
            },
          ),
      ],
    );
  }
}
