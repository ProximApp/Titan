import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:titan/feed/class/news.dart';
import 'package:titan/feed/providers/news_list_provider.dart';
import 'package:titan/feed/ui/feed.dart';
import 'package:titan/feed/ui/pages/main_page/dotted_vertical_line.dart';
import 'package:titan/feed/ui/pages/main_page/main_page_row.dart';
import 'package:titan/feed/ui/pages/main_page/timeline_item.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/navigation/providers/navbar_visibility_provider.dart';
import 'package:titan/tools/constants.dart';
import 'package:titan/tools/ui/builders/async_child.dart';

class FeedMainPage extends HookConsumerWidget {
  const FeedMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsListProvider);
    final newsListNotifier = ref.watch(newsListProvider.notifier);
    final navbarVisibilityNotifier = ref.watch(
      navbarVisibilityProvider.notifier,
    );
    final showRefreshButton = useState(false);
    final localizeWithContext = AppLocalizations.of(context)!;

    final itemScrollController = useMemoized(() => ItemScrollController());
    final itemPositionsListener = useMemoized(
      () => ItemPositionsListener.create(),
    );
    final lastFirstIndex = useRef<int?>(null);

    Future<void> onRefresh() async {
      await newsListNotifier.loadNewsList();
    }

    List<News> withDisplayDates(List<News> news) {
      final result = <News>[];

      DateTime? lastStart;
      for (final item in news) {
        if (lastStart == null || item.start != lastStart) {
          result.add(item.copyWith(displayDate: item.start));
          lastStart = item.start;
        } else {
          result.add(item.copyWith(displayDate: null));
        }
      }

      return result;
    }

    final now = DateTime.now();
    final newsList = news.value!;

    final pastNews = withDisplayDates(
      newsList
          .where(
            (item) =>
                item.end != null && item.end!.isBefore(now) ||
                item.end == null && item.start.isBefore(now),
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start)),
    );

    final ongoingNews =
        newsList
            .where(
              (item) =>
                  item.start.isBefore(now) &&
                  (item.end != null && item.end!.isAfter(now)),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (ongoingNews.isNotEmpty) {
      ongoingNews[0] = ongoingNews[0].copyWith(displayDate: now);
    }

    final futureNews = withDisplayDates(
      newsList.where((item) => item.start.isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start)),
    );

    final sortedNews = [...pastNews, ...ongoingNews, ...futureNews];

    useEffect(() {
      if (news.hasValue && news.value!.isNotEmpty) {
        Future.microtask(() async {
          final now = DateTime.now();

          final upcomingIndex = sortedNews.indexWhere(
            (item) =>
                item.start.isAfter(now) ||
                (item.end != null && item.end!.isAfter(now)),
          );

          if (upcomingIndex != -1 && itemScrollController.isAttached) {
            await itemScrollController.scrollTo(
              index: upcomingIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            navbarVisibilityNotifier.show();
          }
        });
        void listener() {
          final positions = itemPositionsListener.itemPositions.value;
          if (positions.isEmpty) return;
          final visiblePositions = positions.where(
            (p) => p.itemLeadingEdge >= 0 && p.itemLeadingEdge <= 1,
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
              showRefreshButton.value = false;
            } else if (firstVisible < lastIndex) {
              navbarVisibilityNotifier.show();
              showRefreshButton.value = true;
            }
          }

          lastFirstIndex.value = firstVisible;
        }

        itemPositionsListener.itemPositions.addListener(listener);
        return () =>
            itemPositionsListener.itemPositions.removeListener(listener);
      }
      return null;
    }, [news]);

    Future<void> handleRefresh() async {
      showRefreshButton.value = false;
      await onRefresh();
    }

    return FeedTemplate(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                MainPageRow(),
                const SizedBox(height: 10),

                Expanded(
                  child: AsyncChild(
                    value: news,
                    builder: (context, news) => news.isEmpty
                        ? Center(
                            child: Text(
                              localizeWithContext.feedNoNewsAvailable,
                              style: TextStyle(
                                fontSize: 16,
                                color: ColorConstants.tertiary,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ScrollablePositionedList.builder(
                                  itemCount: news.length + 1,
                                  itemScrollController: itemScrollController,
                                  itemPositionsListener: itemPositionsListener,
                                  itemBuilder: (context, index) {
                                    if (index == news.length) {
                                      return const SizedBox(height: 80);
                                    }
                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Stack(
                                          children: [
                                            Positioned(
                                              left: 20,
                                              top: 0,
                                              bottom: 0,
                                              child: DottedVerticalLine(),
                                            ),
                                            TimeLineItem(
                                              item: sortedNews[index],
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: showRefreshButton.value ? 10 : -10,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              opacity: showRefreshButton.value ? 1.0 : 0.0,
              child: Center(
                child: GestureDetector(
                  onTap: handleRefresh,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.main,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.onMain.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeroIcon(
                          HeroIcons.arrowPath,
                          size: 16,
                          color: ColorConstants.background,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizeWithContext.feedRefresh,
                          style: TextStyle(
                            color: ColorConstants.background,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
