import 'dart:convert';
import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/feed/providers/news_list_provider.dart';
import 'package:titan/feed/ui/pages/main_page/feed_timeline.dart';
import 'package:titan/feed/ui/pages/main_page/pagination_scroll_hook.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
// `Size` is hidden: the generated models export one, and this test needs
// Flutter's.
import 'package:titan/generated/openapi.swagger.dart' hide Size;
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/repository/repository.dart';

class MockNewsRepository extends Mock implements Openapi {}

/// The notifier anchors its window on `now - newsUpcomingGracePeriod`;
/// fixtures must straddle that same instant for the window to open on
/// "today".
DateTime get testAnchor => DateTime.now().subtract(newsUpcomingGracePeriod);

/// Minimal valid 1x1 transparent PNG, so `Image.memory` decodes without
/// touching the asset bundle or platform channels.
final _pngBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

News news(String id, {required DateTime start, DateTime? end}) => News(
  id: id,
  title: 'News $id',
  start: start,
  end: end,
  entity: 'BDE',
  location: null,
  actionStart: null,
  module: 'event',
  moduleObjectId: '',
  status: enums.NewsStatus.published,
);

chopper.Response<List<News>> ok(List<News> body) =>
    chopper.Response(http.Response('[]', 200), body);

/// Mirrors the feed main page wiring: the pagination hook drives a plain
/// scroll view holding the timeline.
class TestFeed extends HookConsumerWidget {
  const TestFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsListProvider);
    final pagination = ref.watch(newsPaginationProvider);
    final notifier = ref.watch(newsListProvider.notifier);
    final scrollController = useFeedPagination(ref);

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 600,
          child: news.when(
            data: (items) => items.isEmpty
                ? const Text('empty feed')
                : SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: FeedTimeline(
                      items: items,
                      isLoadingNextPage: pagination.isLoadingNext,
                      nextPageFailed: pagination.nextFailed,
                      onLoadNextPage: notifier.loadNextPage,
                      isLoadingPreviousPage: pagination.isLoadingPrevious,
                      previousPageFailed: pagination.previousFailed,
                      onLoadPreviousPage: notifier.loadPreviousPage,
                    ),
                  ),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('error: $error'),
          ),
        ),
      ),
    );
  }
}

// The timeline keys each item on its News *instance* (GlobalObjectKey
// compares by identity), and the very same instances flow from the stubbed
// responses through the provider into the timeline. Registering the fixtures
// lets assertions address them by id.
final _instances = <String, News>{};

List<News> register(List<News> page) {
  for (final item in page) {
    _instances[item.id] = item;
  }
  return page;
}

Key itemKey(String id) => GlobalObjectKey(_instances[id]!);

void main() {
  late MockNewsRepository mockRepository;
  late ProviderContainer container;

  List<News> upcomingPage(DateTime anchor, {int from = 0}) => register(
    List.generate(
      newsPageSize,
      (i) => news(
        'up-${from + i}',
        start: anchor.add(Duration(days: from + i + 1)),
      ),
    ),
  );

  List<News> pastPage(DateTime anchor, {int from = 0}) => register(
    List.generate(
      newsPageSize,
      (i) => news(
        'past-${from + i}',
        start: anchor.subtract(Duration(days: from + i + 1)),
      ),
    ),
  );

  void stubImages() {
    // The bytes must sit in the base http.Response: FileResponse.fileBytes
    // reads `base.bodyBytes`, not the chopper `body`.
    when(
      () => mockRepository.feedNewsNewsIdImageGet(newsId: any(named: 'newsId')),
    ).thenAnswer(
      (_) async =>
          chopper.Response(http.Response.bytes(_pngBytes, 200), _pngBytes),
    );
  }

  void stubInitial(List<News> upcoming, List<News> past) {
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

  void stubNext(List<News> page) {
    when(
      () => mockRepository.feedNewsGet(
        limit: newsPageSize,
        offset: newsPageSize,
        order: 'asc',
        startAfter: any(named: 'startAfter'),
        startBefore: any(named: 'startBefore'),
      ),
    ).thenAnswer((_) async => ok(page));
  }

  void stubPrevious(List<News> page) {
    when(
      () => mockRepository.feedNewsGet(
        limit: newsPageSize,
        offset: newsPageSize,
        order: 'desc',
        startAfter: any(named: 'startAfter'),
        startBefore: any(named: 'startBefore'),
      ),
    ).thenAnswer((_) async => ok(page));
  }

  Future<void> pumpFeed(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const TestFeed(),
        ),
      ),
    );
    // Flush the initial load and the image microtasks.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Scrolls until the position stops changing (BouncingScrollPhysics balls
  /// out; the footer spinners never settle, so no pumpAndSettle).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(() {
    _instances.clear();
    mockRepository = MockNewsRepository();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  group('feed pagination on screen', () {
    testWidgets('opens the window on today: upcoming below the viewport top', (
      tester,
    ) async {
      final anchor = testAnchor;
      stubInitial(upcomingPage(anchor), pastPage(anchor));
      stubImages();
      await pumpFeed(tester);

      // The window opens on "today": the most recent past event is fully
      // visible at the top of the viewport, and the oldest upcoming one is
      // on screen right below it.
      final pastRect = tester.getRect(find.byKey(itemKey('past-0')));
      final upcomingRect = tester.getRect(find.byKey(itemKey('up-0')));
      expect(pastRect.top, lessThanOrEqualTo(60));
      expect(
        pastRect.bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byType(SingleChildScrollView)).bottom,
        ),
      );
      expect(upcomingRect.top, greaterThan(pastRect.bottom));
      expect(
        upcomingRect.top,
        lessThan(tester.getRect(find.byType(SingleChildScrollView)).bottom),
      );
      // The viewport actually scrolled: the oldest past events stay above.
      expect(
        tester.getRect(find.byKey(itemKey('past-9'))).bottom,
        lessThanOrEqualTo(pastRect.bottom),
      );
    });

    testWidgets(
      'scrolling to the bottom loads the next page of upcoming events',
      (tester) async {
        final anchor = testAnchor;
        stubInitial(upcomingPage(anchor), pastPage(anchor));
        stubImages();
        await pumpFeed(tester);

        expect(find.byKey(itemKey('up-${newsPageSize - 1}')), findsOneWidget);
        stubNext(upcomingPage(anchor, from: newsPageSize));
        expect(find.byKey(itemKey('up-$newsPageSize')), findsNothing);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -20000),
        );
        await settle(tester);

        expect(find.byKey(itemKey('up-$newsPageSize')), findsOneWidget);
      },
    );

    testWidgets(
      'scrolling to the top prepends past events and keeps the reading position',
      (tester) async {
        final anchor = testAnchor;
        stubInitial(upcomingPage(anchor), pastPage(anchor));
        stubImages();
        await pumpFeed(tester);

        ScrollPosition positionOf() =>
            tester.state<ScrollableState>(find.byType(Scrollable)).position;
        double dyOf(String id) => tester.getRect(find.byKey(itemKey(id))).top;

        // Walk towards the top like a user would (no fling): cross the
        // trigger edge, snapshot what the user is reading while the page is
        // in flight, then let the prepend land.
        stubPrevious(pastPage(anchor, from: newsPageSize));
        positionOf().jumpTo(100); // within the edge: triggers the load
        await tester.pump();
        // Topmost fully visible card while the load is in flight.
        final readingTopAtTrigger = dyOf('past-8');
        await settle(tester);

        // A page of older events was prepended above.
        expect(find.byKey(itemKey('past-$newsPageSize')), findsOneWidget);
        // And the card the user was reading did not move in the viewport.
        expect(
          dyOf('past-8'),
          moreOrLessEquals(readingTopAtTrigger, epsilon: 2),
        );
      },
    );

    testWidgets('an exhausted direction stops fetching', (tester) async {
      final anchor = testAnchor;
      stubInitial(upcomingPage(anchor), pastPage(anchor));
      stubImages();
      await pumpFeed(tester);

      // The next page comes back empty: the direction is exhausted.
      stubNext(const []);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -20000),
      );
      await settle(tester);
      verify(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: newsPageSize,
          order: 'asc',
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).called(1);

      // Keep scrolling: no further fetch is issued.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -20000),
      );
      await settle(tester);
      verifyNever(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: 2 * newsPageSize,
          order: any(named: 'order'),
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      );
    });

    testWidgets('a failed next page shows a retry button that reloads it', (
      tester,
    ) async {
      final anchor = testAnchor;
      stubInitial(upcomingPage(anchor), pastPage(anchor));
      stubImages();
      await pumpFeed(tester);

      when(
        () => mockRepository.feedNewsGet(
          limit: newsPageSize,
          offset: newsPageSize,
          order: 'asc',
          startAfter: any(named: 'startAfter'),
          startBefore: any(named: 'startBefore'),
        ),
      ).thenAnswer((_) async => throw Exception('network down'));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -20000),
      );
      await settle(tester);

      // The timeline is intact and the bottom footer offers a retry.
      expect(find.text('Retry'), findsOneWidget);

      stubNext(upcomingPage(anchor, from: newsPageSize));
      await tester.tap(find.text('Retry'));
      await settle(tester);

      expect(find.text('Retry'), findsNothing);
      expect(find.byKey(itemKey('up-$newsPageSize')), findsOneWidget);
    });
  });
}
