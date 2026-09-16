import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/date_time_json.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

const newsPageSize = 10;

const newsUpcomingGracePeriod = Duration(hours: 2);

class _FeedPagination {
  int fetched = 0;
  bool hasMore = true;
  bool isLoading = false;
}

class NewsPaginationState {
  final bool isLoadingPrevious;
  final bool previousFailed;
  final bool isLoadingNext;
  final bool nextFailed;

  const NewsPaginationState({
    this.isLoadingPrevious = false,
    this.previousFailed = false,
    this.isLoadingNext = false,
    this.nextFailed = false,
  });

  NewsPaginationState copyWith({
    bool? isLoadingPrevious,
    bool? previousFailed,
    bool? isLoadingNext,
    bool? nextFailed,
  }) => NewsPaginationState(
    isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
    previousFailed: previousFailed ?? this.previousFailed,
    isLoadingNext: isLoadingNext ?? this.isLoadingNext,
    nextFailed: nextFailed ?? this.nextFailed,
  );
}

class NewsPaginationNotifier extends Notifier<NewsPaginationState> {
  @override
  NewsPaginationState build() => const NewsPaginationState();

  void set(NewsPaginationState paginationState) => state = paginationState;
}

final newsPaginationProvider =
    NotifierProvider<NewsPaginationNotifier, NewsPaginationState>(
      NewsPaginationNotifier.new,
    );

enum _Direction {
  upcoming._('asc'),
  past._('desc');

  final String order;

  const _Direction._(this.order);
}

class NewsListNotifier extends ListNotifierAPI<News> {
  Openapi get newsRepository => ref.watch(repositoryProvider);

  AsyncValue<List<News>> allNews = const AsyncValue.loading();

  DateTime? _anchor;

  int _generation = 0;

  final _FeedPagination _upcoming = _FeedPagination();
  final _FeedPagination _past = _FeedPagination();

  final Set<String> _knownIds = {};

  List<String> _filterEntities = [];
  List<String> _filterModules = [];

  DateTime? get anchor => _anchor;

  @override
  AsyncValue<List<News>> build() {
    loadNewsList();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<News>>> loadNewsList() async {
    final anchor = DateTime.now().subtract(newsUpcomingGracePeriod);
    try {
      final results = await Future.wait([
        newsRepository.feedNewsGet(
          limit: newsPageSize,
          offset: 0,
          order: _Direction.upcoming.order,
          startAfter: dateTimeToJson(anchor),
        ),

        newsRepository.feedNewsGet(
          limit: newsPageSize,
          offset: 0,
          order: _Direction.past.order,
          startBefore: dateTimeToJson(anchor),
        ),
      ]);

      final upcomingPage = results[0].body ?? const [];
      final pastPage = results[1].body ?? const [];

      _generation++;
      _anchor = anchor;
      _upcoming
        ..fetched = upcomingPage.length
        ..hasMore = upcomingPage.length >= newsPageSize;
      _past
        ..fetched = pastPage.length
        ..hasMore = pastPage.length >= newsPageSize;

      _knownIds.clear();

      allNews = AsyncValue.data(
        _absorb(const [], [...pastPage, ...upcomingPage], prepend: false)
          ..sort(compareNews),
      );
    } catch (err) {
      if (err is AppException && err.type == ErrorType.tokenExpire) rethrow;

      if (allNews.value == null) {
        allNews = AsyncValue.error(err, StackTrace.current);
      }
    }
    _setPagination(const NewsPaginationState());
    _applyFilters();
    return allNews;
  }

  Future<void> loadNextPage() => _loadPage(_Direction.upcoming);

  Future<void> loadPreviousPage() => _loadPage(_Direction.past);

  Future<void> _loadPage(_Direction direction) async {
    final anchor = _anchor;
    final pagination = direction == _Direction.upcoming ? _upcoming : _past;
    if (anchor == null || pagination.isLoading || !pagination.hasMore) return;
    pagination.isLoading = true;
    final isLoadingNext = direction == _Direction.upcoming;
    final generation = _generation;

    void setDirectionState({required bool isLoading, required bool failed}) =>
        _setPagination(
          ref
              .read(newsPaginationProvider)
              .copyWith(
                isLoadingNext: isLoadingNext ? isLoading : null,
                nextFailed: isLoadingNext ? failed : null,
                isLoadingPrevious: isLoadingNext ? null : isLoading,
                previousFailed: isLoadingNext ? null : failed,
              ),
        );
    setDirectionState(isLoading: true, failed: false);

    try {
      final response = await newsRepository.feedNewsGet(
        limit: newsPageSize,
        offset: pagination.fetched,
        order: direction.order,
        startAfter: isLoadingNext ? dateTimeToJson(anchor) : null,
        startBefore: isLoadingNext ? null : dateTimeToJson(anchor),
      );

      if (generation != _generation) return;
      final page = response.body ?? const [];
      pagination.fetched += page.length;
      if (page.length < newsPageSize) pagination.hasMore = false;
      allNews = AsyncValue.data(
        _absorb(allNews.value ?? const [], page, prepend: !isLoadingNext),
      );
      _applyFilters();
      setDirectionState(isLoading: false, failed: false);
    } catch (err) {
      if (err is AppException && err.type == ErrorType.tokenExpire) rethrow;
      if (generation != _generation) return;

      setDirectionState(isLoading: false, failed: true);
    } finally {
      pagination.isLoading = false;
    }
  }

  void filterNews(List<String> entities, List<String> modules) {
    _filterEntities = entities;
    _filterModules = modules;
    _applyFilters();
  }

  void resetFilters() {
    _filterEntities = [];
    _filterModules = [];
    _applyFilters();
  }

  void _setPagination(NewsPaginationState paginationState) {
    ref.read(newsPaginationProvider.notifier).set(paginationState);
  }

  void _applyFilters() {
    allNews.when(
      data: (all) {
        state = AsyncValue.data(
          all
              .where(
                (news) =>
                    (_filterEntities.isEmpty ||
                        _filterEntities.contains(news.entity)) &&
                    (_filterModules.isEmpty ||
                        _filterModules.contains(news.module)),
              )
              .toList(),
        );
      },
      loading: () => state = const AsyncValue.loading(),
      error: (error, stack) => state = AsyncValue.error(error, stack),
    );
  }

  List<News> _absorb(
    List<News> current,
    List<News> page, {
    required bool prepend,
  }) {
    final fresh = <News>[];
    for (final news in page) {
      if (_knownIds.add(news.id)) fresh.add(news);
    }
    return prepend ? [...fresh.reversed, ...current] : [...current, ...fresh];
  }
}

int compareNews(News a, News b) {
  if (a.start != b.start) return a.start.compareTo(b.start);
  final aEnd = a.end;
  final bEnd = b.end;
  if (aEnd == null || bEnd == null) {
    if (aEnd == bEnd) return a.id.compareTo(b.id);
    return aEnd == null ? 1 : -1;
  }
  if (aEnd != bEnd) return aEnd.compareTo(bEnd);
  return a.id.compareTo(b.id);
}

final newsListProvider =
    NotifierProvider<NewsListNotifier, AsyncValue<List<News>>>(
      NewsListNotifier.new,
    );
