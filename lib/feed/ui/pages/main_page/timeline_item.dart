import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:titan/feed/class/news.dart';
import 'package:titan/feed/tools/news_helper.dart';
import 'package:titan/feed/ui/pages/main_page/event_action.dart';
import 'package:titan/feed/ui/pages/main_page/event_card.dart';
import 'package:titan/feed/ui/widgets/event_card_text_content.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/constants.dart';

class TimeLineItem extends ConsumerWidget {
  final News item;

  const TimeLineItem({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final localizeWithContext = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(right: 10),
                width: 55,
                height: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (item.displayDate != null)
                      Container(
                        color: ColorConstants.background,
                        child: Text(
                          DateFormat.d(locale.toString()).format(item.start),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.main,
                          ),
                        ),
                      ),
                    if (item.displayDate != null)
                      Container(
                        color: ColorConstants.background,
                        child: Text(
                          DateFormat.MMM(
                            locale.toString(),
                          ).format(item.start).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.onTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: EventCard(item: item),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 45),
            child: EventCardTextContent(
              item: item,
              localizeWithContext: localizeWithContext,
            ),
          ),
          if (item.actionStart != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 11, right: 37, top: 3),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.background,
                        border: Border.all(
                          color: ColorConstants.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: EventAction(
                      title: getActionTitle(item, context),
                      waitingTitle: (timeToGo) =>
                          getWaitingTitle(item, context, timeToGo: timeToGo),
                      subtitle: getActionSubtitle(item, context),
                      onActionPressed: () =>
                          getActionButtonAction(item, context, ref),
                      actionEnableButtonText: getActionEnableButtonText(
                        item,
                        context,
                      ),
                      actionValidatedButtonText: getActionValidatedButtonText(
                        item,
                        context,
                      ),
                      isActionValidated: false,
                      eventEnd: item.end,
                      timeOpening: item.actionStart,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
