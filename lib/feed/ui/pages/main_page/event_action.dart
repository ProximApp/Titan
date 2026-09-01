import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/constants.dart';

class EventAction extends HookWidget {
  final String title,
      subtitle,
      actionEnableButtonText,
      actionValidatedButtonText;
  final String Function(String timeToGo) waitingTitle;
  final DateTime? timeOpening, eventEnd;
  final VoidCallback? onActionPressed;
  final bool isActionValidated;
  final bool isDisabled;
  final String? disabledLabel;

  const EventAction({
    super.key,
    required this.title,
    required this.subtitle,
    this.onActionPressed,
    required this.actionEnableButtonText,
    required this.actionValidatedButtonText,
    required this.isActionValidated,
    required this.timeOpening,
    required this.eventEnd,
    required this.waitingTitle,
    this.isDisabled = false,
    this.disabledLabel,
  });

  static const _secondaryTextStyle = TextStyle(
    fontSize: 11,
    color: ColorConstants.secondary,
  );

  @override
  Widget build(BuildContext context) {
    final now = useState(DateTime.now());
    final locale = Localizations.localeOf(context);

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = DateTime.now();
      });

      return timer.cancel;
    }, []);

    final isActionEnabled =
        !isDisabled &&
        timeOpening != null &&
        timeOpening!.isBefore(now.value) &&
        eventEnd != null &&
        eventEnd!.isAfter(now.value);

    final isWaiting = timeOpening != null && timeOpening!.isAfter(now.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWaiting ? AppLocalizations.of(context)!.feedGetReady : title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.onTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              timeOpening != null &&
                      eventEnd != null &&
                      eventEnd!.isAfter(now.value) &&
                      timeOpening!.isAfter(now.value)
                  ? Timeago(
                      date: timeOpening!,
                      locale: '${locale.languageCode}_short',
                      allowFromNow: true,
                      refreshRate: const Duration(seconds: 1),
                      builder: (context, str) => AutoSizeText(
                        waitingTitle(str),
                        style: _secondaryTextStyle,
                        minFontSize: 8,
                        maxLines: 2,
                      ),
                    )
                  : AutoSizeText(
                      subtitle,
                      style: _secondaryTextStyle,
                      minFontSize: 8,
                      maxLines: 2,
                    ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: GestureDetector(
            onTap: () {
              if (isActionEnabled && !isActionValidated) {
                onActionPressed!.call();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActionValidated
                    ? ColorConstants.tertiary
                    : ColorConstants.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ColorConstants.tertiary.withValues(
                    alpha: isActionEnabled && !isActionValidated ? 1 : 0.5,
                  ),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  isDisabled && disabledLabel != null
                      ? disabledLabel!
                      : isActionValidated
                      ? actionValidatedButtonText
                      : actionEnableButtonText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        (isActionValidated
                                ? ColorConstants.background
                                : ColorConstants.tertiary)
                            .withValues(
                              alpha: isActionEnabled && !isActionValidated
                                  ? 1
                                  : 0.5,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
