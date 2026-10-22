import 'package:flutter/material.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/loader.dart';

class PaginationFooter extends StatelessWidget {
  final bool isLoading;
  final bool showRetry;
  final VoidCallback onRetry;

  final bool isTop;

  const PaginationFooter({
    super.key,
    required this.isLoading,
    required this.showRetry,
    required this.onRetry,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.0, bottom: isTop ? 12.0 : 80.0),
      child: Center(
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: Loader())
            : showRetry
            ? TextButton.icon(
                onPressed: onRetry,
                icon: HeroIcon(
                  HeroIcons.arrowPath,
                  size: 16,
                  color: ColorConstants.tertiary,
                ),
                label: Text(
                  AppLocalizations.of(context)!.retry,
                  style: TextStyle(color: ColorConstants.tertiary),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
