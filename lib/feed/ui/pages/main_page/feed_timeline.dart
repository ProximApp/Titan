import 'package:flutter/material.dart';
import 'package:titan/feed/ui/pages/main_page/time_line_item.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

class FeedTimeline extends StatelessWidget {
  final List<News> items;
  final Function(News item)? onItemTap;
  final bool isAdmin;
  final ScrollController? controller;

  const FeedTimeline({
    super.key,
    required this.items,
    this.onItemTap,
    required this.isAdmin,
    this.controller,
  });

  // Mirrors the height calculation in TimelineItem's LayoutBuilder exactly.
  // Must stay in sync with time_line_item.dart if that layout changes.
  static double _itemHeight(News item, double crossAxisExtent) {
    final eventCardWidth = crossAxisExtent - 70;
    final eventCardHeight = eventCardWidth / (851 / 315);
    final baseHeight = 30 + eventCardHeight + 20;
    return item.actionStart != null ? baseHeight + 40 : baseHeight;
  }

  @override
  Widget build(BuildContext context) {
    items.sort((a, b) {
      if (a.start == b.start) {
        if (a.end == null && b.end == null) return 0;
        if (a.end == null) return -1;
        if (b.end == null) return 1;
        return a.end!.compareTo(b.end!);
      }
      return a.start.compareTo(b.start);
    });

    return ListView.builder(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length + 1, // +1 trailing spacer
      itemExtentBuilder: (index, dimensions) {
        if (index == items.length) return 80; // trailing SizedBox height
        return _itemHeight(items[index], dimensions.crossAxisExtent);
      },
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const SizedBox(height: 80);
        }
        final item = items[index];
        return TimelineItem(
          item: item,
          onTap: onItemTap != null ? () => onItemTap!(item) : null,
        );
      },
    );
  }
}
