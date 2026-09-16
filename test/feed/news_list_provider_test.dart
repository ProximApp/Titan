import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/feed/providers/news_list_provider.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

class MockNewsRepository extends Mock implements Openapi {}

News news(
  String id, {
  required DateTime start,
  String entity = 'BDE',
  String module = 'event',
  DateTime? end,
}) => News(
  id: id,
  title: 'News $id',
  start: start,
  end: end,
  entity: entity,
  location: null,
  actionStart: null,
  module: module,
  moduleObjectId: '',
  status: enums.NewsStatus.published,
);

chopper.Response<List<News>> ok(List<News> body) =>
    chopper.Response(http.Response('[]', 200), body);

void main() {
  group('NewsListNotifier pagination', () {
    late MockNewsRepository mockRepository;
    late ProviderContainer container;
    late NewsListNotifier provider;

    // Anchor used by the notifier: now minus the upcoming grace period. The
    // notifier computes its own anchor (microseconds later), so anchor
    // assertions use a tolerance.
    late DateTime anchor;

    List<News> upcomingPage1 = [];
    List<News> pastPage1 = [];

    void stubFetch({required List<News> upcoming, required List<News> past}) {
      when(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: 0,
          order: 'asc',
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).thenAnswer((_) async => ok(upcoming));
      when(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: 0,
          order: 'desc',
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).thenAnswer((_) async => ok(past));
    }

    setUp(() {
      mockRepository = MockNewsRepository();
      anchor = DateTime.now().subtract(newsUpcomingGracePeriod);
      upcomingPage1 = [
        news('upcoming-1', start: anchor.add(const Duration(days: 2))),
        news('upcoming-2', start: anchor.add(const Duration(days: 3))),
      ];
      pastPage1 = [
        news('past-1', start: anchor.subtract(const Duration(days: 1))),
        news('past-2', start: anchor.subtract(const Duration(days: 2))),
      ];
      // Default stub for the build()-time auto-load.
      stubFetch(upcoming: upcomingPage1, past: pastPage1);
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      provider = container.read(newsListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test(
      'initial load fetches upcoming then past pages around the anchor',
      () async {
        final result = await provider.loadNewsList();

        expect(result.value!.map((n) => n.id), [
          'past-2',
          'past-1',
          'upcoming-1',
          'upcoming-2',
        ]);
        expect(provider.anchor, isNotNull);
        expect(
          provider.anchor!.difference(anchor).inSeconds.abs(),
          lessThan(5),
        );
        // Both windows returned fewer than a full page: nothing more to load.
        verifyNever(
          () => mockRepository.feedNewsGet(
            limit: newsPageSize,
            offset: newsPageSize,
            order: any(named: 'order'),
            startAfter: any(named: 'startAfter'),
            startBefore: any(named: 'startBefore'),
          ),
        );
      },
    );

    test(
      'loadNextPage appends upcoming events in chronological order',
      () async {
        // Upcoming window at exactly page size: a next page may exist.
        final fullUpcoming = List.generate(
          newsPageSize,
          (i) => news('up-$i', start: anchor.add(Duration(days: i + 1))),
        );
        stubFetch(upcoming: fullUpcoming, past: pastPage1);
        await provider.loadNewsList();

        final nextPage = [
          news(
            'up-$newsPageSize',
            start: anchor.add(Duration(days: newsPageSize + 1)),
          ),
        ];
        when(
          () => mockRepository.feedNewsGet(
            limit: newsPageSize,
            offset: newsPageSize,
            order: 'asc',
            startAfter: any(named: 'startAfter'),
            startBefore: any(named: 'startBefore'),
          ),
        ).thenAnswer((_) async => ok(nextPage));

        await provider.loadNextPage();

        expect(provider.state.value!.last.id, 'up-$newsPageSize');
        expect(provider.state.value!.first.id, 'past-2');
      },
    );

    test(
      'loadPreviousPage reverses the desc page and prepends it chronologically',
      () async {
        final fullPast = List.generate(
          newsPageSize,
          (i) => news('past-$i', start: anchor.subtract(Duration(days: i + 1))),
        );
        stubFetch(upcoming: upcomingPage1, past: fullPast);
        await provider.loadNewsList();

        // Hyperion serves past pages descending: newest first. The notifier
        // must reverse them before prepending.
        final previousPage = [
          news('past-newer', start: anchor.subtract(const Duration(days: 11))),
          news('past-older', start: anchor.subtract(const Duration(days: 12))),
        ];
        when(
          () => mockRepository.feedNewsGet(
            limit: newsPageSize,
            offset: newsPageSize,
            order: 'desc',
            startAfter: any(named: 'startAfter'),
            startBefore: any(named: 'startBefore'),
          ),
        ).thenAnswer((_) async => ok(previousPage));

        await provider.loadPreviousPage();

        final ids = provider.state.value!.map((n) => n.id).toList();
        expect(ids[0], 'past-older');
        expect(ids[1], 'past-newer');
        // The list is chronological: the oldest initially loaded event comes
        // right after the freshly prepended ones.
        expect(ids[2], 'past-${newsPageSize - 1}');
      },
    );

    test(
      'loadNextPage and loadPreviousPage are no-ops while loading',
      () async {
        final fullUpcoming = List.generate(
          newsPageSize,
          (i) => news('up-$i', start: anchor.add(Duration(days: i + 1))),
        );
        stubFetch(upcoming: fullUpcoming, past: pastPage1);
        await provider.loadNewsList();

        final pending = Completer<chopper.Response<List<News>>>();
        when(
          () => mockRepository.feedNewsGet(
            limit: newsPageSize,
            offset: newsPageSize,
            order: 'asc',
            startAfter: any(named: 'startAfter'),
            startBefore: any(named: 'startBefore'),
          ),
        ).thenAnswer((_) => pending.future);

        final first = provider.loadNextPage();
        await provider.loadNextPage(); // ignored: first is still in flight

        pending.complete(
          ok([news('up-late', start: anchor.add(const Duration(days: 99)))]),
        );
        await first;
        verifyNever(
          () => mockRepository.feedNewsGet(
            limit: newsPageSize,
            offset: 2 * newsPageSize,
            order: any(named: 'order'),
            startAfter: any(named: 'startAfter'),
            startBefore: any(named: 'startBefore'),
          ),
        );
      },
    );

    test('a page completing after a refresh is discarded', () async {
      stubFetch(upcoming: upcomingPage1, past: pastPage1);
      await provider.loadNewsList();

      // A next page hangs in flight while the user pulls a refresh.
      final pending = Completer<chopper.Response<List<News>>>();
      when(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: newsPageSize,
          order: 'asc',
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).thenAnswer((_) => pending.future);
      final stalePage = provider.loadNextPage();

      final refreshedUpcoming = [
        news('fresh-up', start: anchor.add(const Duration(days: 5))),
      ];
      stubFetch(upcoming: refreshedUpcoming, past: pastPage1);
      await provider.loadNewsList();

      // The stale page lands after the fresh window: it must be dropped.
      pending.complete(
        ok([news('stale-up', start: anchor.add(const Duration(days: 99)))]),
      );
      await stalePage;

      final ids = provider.state.value!.map((n) => n.id).toList();
      expect(ids, isNot(contains('stale-up')));
      expect(ids, contains('fresh-up'));
      // No leftover failure or spinner from the discarded page.
      final pagination = container.read(newsPaginationProvider);
      expect(pagination.isLoadingNext, isFalse);
      expect(pagination.nextFailed, isFalse);
    });

    test('a failed refresh keeps the already loaded news', () async {
      stubFetch(upcoming: upcomingPage1, past: pastPage1);
      await provider.loadNewsList();
      final idsBefore = provider.state.value!.map((n) => n.id).toList();

      when(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: 0,
          order: any(named: 'order'),
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).thenAnswer((_) async => throw Exception('network down'));

      final result = await provider.loadNewsList();

      expect(result.hasValue, isTrue);
      expect(result.value!.map((n) => n.id), idsBefore);
    });

    test(
      'one direction failing does not clear the other direction state',
      () async {
        // Both windows full so a page is actually fetched in each direction,
        // then the initial-load stubs are re-registered BEFORE the failing
        // one (later stubs win in mocktail).
        final fullUpcoming = List.generate(
          newsPageSize,
          (i) => news('up-$i', start: anchor.add(Duration(days: i + 1))),
        );
        final fullPast = List.generate(
          newsPageSize,
          (i) => news('past-$i', start: anchor.subtract(Duration(days: i + 1))),
        );
        stubFetch(upcoming: fullUpcoming, past: fullPast);
        await provider.loadNewsList();

        // The previous page fails: the top footer shows a retry button.
        when(
          () => mockRepository.feedNewsGet(
            limit: newsPageSize,
            offset: newsPageSize,
            order: 'desc',
            startAfter: any(named: 'startAfter'),
            startBefore: any(named: 'startBefore'),
          ),
        ).thenAnswer((_) async => throw Exception('boom'));
        await provider.loadPreviousPage();
        expect(container.read(newsPaginationProvider).previousFailed, isTrue);

        // A next-page load starts and must not hide the top retry button.
        final pending = Completer<chopper.Response<List<News>>>();
        when(
          () => mockRepository.feedNewsGet(
            limit: newsPageSize,
            offset: newsPageSize,
            order: 'asc',
            startAfter: any(named: 'startAfter'),
            startBefore: any(named: 'startBefore'),
          ),
        ).thenAnswer((_) => pending.future);
        final next = provider.loadNextPage();
        expect(container.read(newsPaginationProvider).isLoadingNext, isTrue);
        expect(container.read(newsPaginationProvider).previousFailed, isTrue);

        pending.complete(
          ok([news('up-late', start: anchor.add(const Duration(days: 99)))]),
        );
        await next;

        final pagination = container.read(newsPaginationProvider);
        expect(pagination.nextFailed, isFalse);
        // The top footer retry button survives the bottom page load.
        expect(pagination.previousFailed, isTrue);
      },
    );

    test('a failed next page keeps the timeline and offers a retry', () async {
      final fullUpcoming = List.generate(
        newsPageSize,
        (i) => news('up-$i', start: anchor.add(Duration(days: i + 1))),
      );
      stubFetch(upcoming: fullUpcoming, past: pastPage1);
      await provider.loadNewsList();

      when(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: newsPageSize,
          order: 'asc',
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).thenAnswer((_) async => throw Exception('boom'));
      await provider.loadNextPage();

      expect(container.read(newsPaginationProvider).nextFailed, isTrue);
      expect(provider.state.value, hasLength(newsPageSize + pastPage1.length));

      // Retrying after the stub is fixed loads the page.
      when(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: newsPageSize,
          order: 'asc',
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).thenAnswer(
        (_) async => ok([
          news(
            'up-$newsPageSize',
            start: anchor.add(Duration(days: newsPageSize + 1)),
          ),
        ]),
      );
      await provider.loadNextPage();

      expect(container.read(newsPaginationProvider).nextFailed, isFalse);
      expect(provider.state.value!.last.id, 'up-$newsPageSize');
    });

    test(
      'filters only change the displayed list, not the pagination',
      () async {
        await provider.loadNewsList();

        provider.filterNews(['BDE'], []);
        expect(provider.state.value, hasLength(4)); // all fixtures are BDE

        provider.filterNews(['Other'], []);
        expect(provider.state.value, isEmpty);

        provider.resetFilters();
        expect(provider.state.value, hasLength(4));
      },
    );

    test(
      'merge dedupes boundary items re-delivered by inclusive cursors',
      () async {
        // Upcoming window ends exactly at the anchor; the past window starts
        // at the anchor. With inclusive bounds the same item may be delivered
        // to both directions.
        final boundary = news('boundary', start: anchor);
        final fullUpcoming = List.generate(
          newsPageSize - 1,
          (i) => news('up-$i', start: anchor.add(Duration(days: i + 1))),
        )..add(boundary);
        final fullPast = [
          boundary,
          ...List.generate(
            newsPageSize - 1,
            (i) =>
                news('past-$i', start: anchor.subtract(Duration(days: i + 1))),
          ),
        ];
        stubFetch(upcoming: fullUpcoming, past: fullPast);
        await provider.loadNewsList();

        final ids = provider.state.value!.map((n) => n.id).toList();
        expect(ids.where((id) => id == 'boundary'), hasLength(1));
        expect(ids.length, ids.toSet().length);
        // Sorted chronologically across the whole window.
        final starts = provider.state.value!.map((n) => n.start).toList();
        expect(starts, starts.toList()..sort());
      },
    );
  });
}
