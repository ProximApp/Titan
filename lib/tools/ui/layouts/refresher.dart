import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/navigation/ui/scroll_to_hide_navbar.dart';

class Refresher extends HookConsumerWidget {
  final Widget? child;
  final List<Widget>? slivers;
  final Future Function() onRefresh;
  final ScrollController controller;

  const Refresher({
    super.key,
    required this.onRefresh,
    required this.controller,
    this.child,
    this.slivers,
  }) : assert(child != null || slivers != null, 'Provide child or slivers');

  List<Widget> _slivers(BoxConstraints constraints) {
    if (slivers != null) return slivers!;
    return [
      SliverToBoxAdapter(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return ScrollToHideNavbar(
        controller: controller,
        child: LayoutBuilder(
          builder: (context, constraints) => CustomScrollView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: _slivers(constraints),
          ),
        ),
      );
    }
    return Platform.isAndroid ? buildAndroidList(ref) : buildIOSList(ref);
  }

  Widget buildAndroidList(WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) => RefreshIndicator(
      onRefresh: onRefresh,
      child: ScrollToHideNavbar(
        controller: controller,
        child: CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: _slivers(constraints),
        ),
      ),
    ),
  );

  Widget buildIOSList(WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) => ScrollToHideNavbar(
      controller: controller,
      child: CustomScrollView(
        controller: controller,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          ..._slivers(constraints),
        ],
      ),
    ),
  );
}
