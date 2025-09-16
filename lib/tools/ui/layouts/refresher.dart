import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/navigation/ui/scroll_to_hide_navbar.dart';
import 'package:titan/tools/constants.dart';

class Refresher extends HookConsumerWidget {
  final Widget child;
  final Future Function() onRefresh;
  final ScrollController controller;
  const Refresher({
    super.key,
    required this.onRefresh,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: ColorConstants.main,
      onRefresh: onRefresh,
      child: ScrollToHideNavbar(
        controller: controller,
        child: CustomScrollView(
          controller: controller,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverList(delegate: SliverChildListDelegate([child])),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
