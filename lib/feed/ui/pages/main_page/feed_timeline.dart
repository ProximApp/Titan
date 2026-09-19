import 'package:flutter/material.dart';
import 'package:titan/feed/ui/pages/main_page/pagination_footer.dart';
import 'package:titan/feed/ui/pages/main_page/time_line_item.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

class FeedTimeline extends StatelessWidget {
  final List<News> items;
  final Function(News item)? onItemTap;
  final bool isLoadingNextPage;
  final bool nextPageFailed;
  final VoidCallback? onLoadNextPage;
  final bool isLoadingPreviousPage;
  final bool previousPageFailed;
  final VoidCallback? onLoadPreviousPage;

  const FeedTimeline({
    super.key,
    required this.items,
    this.onItemTap,
    this.isLoadingNextPage = false,
    this.nextPageFailed = false,
    this.onLoadNextPage,
    this.isLoadingPreviousPage = false,
    this.previousPageFailed = false,
    this.onLoadPreviousPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PaginationFooter(
          isTop: true,
          isLoading: isLoadingPreviousPage,
          showRetry: previousPageFailed,
          onRetry: onLoadPreviousPage ?? () {},
        ),
        ...items.map(
          (item) => TimelineItem(
            key: GlobalObjectKey(item),
            item: item,
            onTap: onItemTap != null ? () => onItemTap!(item) : null,
          ),
        ),
        PaginationFooter(
          isLoading: isLoadingNextPage,
          showRetry: nextPageFailed,
          onRetry: onLoadNextPage ?? () {},
        ),
      ],
    );
  }
}
