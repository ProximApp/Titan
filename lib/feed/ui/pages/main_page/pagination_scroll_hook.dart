import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/feed/providers/news_list_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';

const feedPaginationEdge = 200.0;

News? feedAnchorItem(List<News> news, DateTime? anchor) {
  if (anchor == null || news.isEmpty) return null;
  final upcomingIndex = news.indexWhere((item) => !item.start.isBefore(anchor));
  if (upcomingIndex == -1) return news.last;
  if (upcomingIndex == 0) return null;
  return news[upcomingIndex - 1];
}

(News, double)? topmostVisibleItem(List<News> news) {
  for (final item in news) {
    final context = GlobalObjectKey(item).currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is RenderBox &&
        renderObject.hasSize &&
        renderObject.localToGlobal(Offset.zero).dy >= -1) {
      return (item, renderObject.localToGlobal(Offset.zero).dy);
    }
  }
  return null;
}

ScrollController useFeedPagination(WidgetRef ref) {
  final newsListNotifier = ref.watch(newsListProvider.notifier);
  final scrollController = useScrollController();
  final hasOpenedWindow = useRef(false);
  final prependAnchor = useRef<(News, double)?>(null);

  void scrollToItem(News item, {double viewportTop = 0}) {
    final itemContext = GlobalObjectKey(item).currentContext;
    if (itemContext == null || !scrollController.hasClients) return;
    final itemBox = itemContext.findRenderObject();
    final viewport = Scrollable.maybeOf(
      itemContext,
    )?.context.findRenderObject();
    if (itemBox is! RenderBox || viewport is! RenderBox) return;

    final relativeTop = itemBox
        .localToGlobal(Offset.zero, ancestor: viewport)
        .dy;
    scrollController.jumpTo(
      scrollController.offset + relativeTop - viewportTop,
    );
  }

  final news = ref.watch(newsListProvider);
  useEffect(() {
    if (hasOpenedWindow.value || !news.hasValue || news.value!.isEmpty) {
      return null;
    }
    hasOpenedWindow.value = true;
    final target = feedAnchorItem(news.value!, newsListNotifier.anchor);
    if (target == null) return null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToItem(target);
    });
    return null;
  }, [news]);

  useEffect(() {
    final anchor = prependAnchor.value;
    if (anchor == null || !news.hasValue) return null;
    prependAnchor.value = null;
    if (!news.value!.contains(anchor.$1)) return null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToItem(anchor.$1, viewportTop: anchor.$2);
    });
    return null;
  }, [news]);

  useEffect(() {
    void onScroll() {
      if (!scrollController.hasClients) return;
      final position = scrollController.position;
      if (position.maxScrollExtent - position.pixels <= feedPaginationEdge) {
        newsListNotifier.loadNextPage();
      }
      if (hasOpenedWindow.value && position.pixels <= feedPaginationEdge) {
        final current = ref.read(newsListProvider).value;
        if (current != null && current.isNotEmpty) {
          prependAnchor.value = topmostVisibleItem(current);
        }
        newsListNotifier.loadPreviousPage();
      }
    }

    scrollController.addListener(onScroll);
    return () => scrollController.removeListener(onScroll);
  }, const []);

  return scrollController;
}
