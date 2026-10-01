import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/feed/providers/admin_news_list_provider.dart';
import 'package:titan/feed/providers/association_event_list_provider.dart';
import 'package:titan/feed/providers/news_list_provider.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/repository/repository.dart';

class MockFeedRepository extends Mock implements Openapi {}

News news(String id, {String? module, String? entity}) => News.empty().copyWith(
  id: id,
  module: module ?? 'module-$id',
  entity: entity ?? 'entity-$id',
);

EventCompleteTicketUrl event(String id) =>
    EventCompleteTicketUrl.empty().copyWith(id: id);

void main() {
  // Every notifier in this file extends ListNotifierAPI: fetch failures land
  // in the state as AsyncError while an expired token is rethrown for the
  // session handler.
  group('Feed list providers (ListNotifierAPI)', () {
    late MockFeedRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockFeedRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('NewsListNotifier', () {
      test(
        'build fetches the news list right away and stores it in allNews',
        () async {
          final all = [news('1'), news('2')];
          when(() => mockRepository.feedNewsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), all),
          );

          // build() fires loadNewsList() itself: reading the notifier starts
          // the fetch, which settles after a microtask.
          final notifier = container.read(newsListProvider.notifier);
          await Future<void>.delayed(Duration.zero);

          final state = container.read(newsListProvider);
          expect(state, isA<AsyncData<List<News>>>());
          expect(state.value, all);
          expect(notifier.allNews.value, all);
        },
      );

      test('build flags the error when the fetch fails', () async {
        when(
          () => mockRepository.feedNewsGet(),
        ).thenThrow(Exception('network down'));

        container.read(newsListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(newsListProvider), isA<AsyncError<List<News>>>());
      });

      test('build rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        // The first stub settles build()'s fire-and-forget load; rethrowing
        // from it would leave an unhandled async error in the zone.
        when(() => mockRepository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), <News>[]),
        );
        final notifier = container.read(newsListProvider.notifier);
        await notifier.loadNewsList();

        when(() => mockRepository.feedNewsGet()).thenThrow(error);

        await expectLater(notifier.loadNewsList(), throwsA(same(error)));
        // tokenExpire is rethrown before any error state is written, so the
        // previous list stays exposed while the session handler logs out.
        expect(container.read(newsListProvider), isA<AsyncData<List<News>>>());
      });

      test(
        'loadNewsList exposes the fetched news and caches it in allNews',
        () async {
          when(() => mockRepository.feedNewsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), <News>[]),
          );
          container.read(newsListProvider.notifier);
          await Future<void>.delayed(Duration.zero);

          final list = [news('1', module: 'event')];
          when(() => mockRepository.feedNewsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), list),
          );

          final result = await container
              .read(newsListProvider.notifier)
              .loadNewsList();

          expect(result.value, list);
          expect(container.read(newsListProvider.notifier).allNews.value, list);
        },
      );

      test(
        'filterNews keeps only news matching the selected modules and entities',
        () async {
          final all = [
            news('1', module: 'event', entity: 'bde'),
            news('2', module: 'event', entity: 'bdf'),
            news('3', module: 'amap', entity: 'bde'),
          ];
          when(() => mockRepository.feedNewsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), all),
          );
          final notifier = container.read(newsListProvider.notifier);
          await Future<void>.delayed(Duration.zero);

          notifier.filterNews(['bde'], ['event']);

          expect(container.read(newsListProvider).value, [all[0]]);
        },
      );

      test('filterNews with empty filters keeps everything', () async {
        final all = [news('1'), news('2')];
        when(() => mockRepository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), all),
        );
        final notifier = container.read(newsListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        notifier.filterNews([], []);

        expect(container.read(newsListProvider).value, all);
      });

      test(
        'filterNews operates on the cached allNews, not on the filtered view',
        () async {
          final all = [news('1'), news('2')];
          when(() => mockRepository.feedNewsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), all),
          );
          final notifier = container.read(newsListProvider.notifier);
          await Future<void>.delayed(Duration.zero);

          notifier.filterNews(['entity-1'], []);
          expect(container.read(newsListProvider).value, [all[0]]);

          // A second filter call would drop everything if it ran against the
          // already-filtered state instead of the cached full list.
          notifier.filterNews([], ['module-2']);
          expect(container.read(newsListProvider).value, [all[1]]);
        },
      );

      test('resetFilters restores the full cached list', () async {
        final all = [news('1'), news('2')];
        when(() => mockRepository.feedNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), all),
        );
        final notifier = container.read(newsListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        notifier.filterNews([news('1').entity], []);
        expect(container.read(newsListProvider).value, [all[0]]);

        notifier.resetFilters();

        expect(container.read(newsListProvider).value, all);
      });

      test(
        'resetFilters falls back to an empty list when nothing was fetched',
        () async {
          final notifier = container.read(newsListProvider.notifier);

          notifier.resetFilters();

          expect(container.read(newsListProvider).value, isEmpty);
        },
      );
    });

    group('AdminNewsListNotifier', () {
      test('build fetches the admin news list right away', () async {
        final all = [news('1')];
        when(() => mockRepository.feedAdminNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), all),
        );

        container.read(adminNewsListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(adminNewsListProvider).value, all);
      });

      test('approveNews replaces the news with the same id', () async {
        final pending = news('1');
        when(() => mockRepository.feedAdminNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [pending]),
        );
        final notifier = container.read(adminNewsListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        when(
          () => mockRepository.feedAdminNewsNewsIdApprovePost(
            newsId: any(named: 'newsId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );

        final approved = pending.copyWith(status: enums.NewsStatus.published);
        final result = await notifier.approveNews(approved);

        expect(result, isTrue);
        expect(container.read(adminNewsListProvider).value, [approved]);
      });

      test('rejectNews replaces the news with the same id', () async {
        final pending = news('1');
        when(() => mockRepository.feedAdminNewsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [pending]),
        );
        final notifier = container.read(adminNewsListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        when(
          () => mockRepository.feedAdminNewsNewsIdRejectPost(
            newsId: any(named: 'newsId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );

        final rejected = pending.copyWith(status: enums.NewsStatus.rejected);
        final result = await notifier.rejectNews(rejected);

        expect(result, isTrue);
        expect(container.read(adminNewsListProvider).value, [rejected]);
      });

      test(
        'approveNews keeps the previous list when the backend rejects it',
        () async {
          final pending = news('1');
          when(() => mockRepository.feedAdminNewsGet()).thenAnswer(
            (_) async =>
                chopper.Response(http.Response('body', 200), [pending]),
          );
          final notifier = container.read(adminNewsListProvider.notifier);
          await Future<void>.delayed(Duration.zero);

          when(
            () => mockRepository.feedAdminNewsNewsIdApprovePost(
              newsId: any(named: 'newsId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<void>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );

          final result = await notifier.approveNews(pending);

          expect(result, isFalse);
          // ListNotifierAPI.update leaves the previous data in place on
          // failure: the UI keeps showing the old list and the caller shows a
          // toast.
          expect(container.read(adminNewsListProvider).value, [pending]);
        },
      );
    });

    group('AssociationEventsListNotifier', () {
      test('starts in the loading state', () {
        expect(
          container.read(associationEventsListProvider),
          isA<AsyncLoading<List<EventCompleteTicketUrl>>>(),
        );
      });

      test('loadAssociationEventList exposes the association events', () async {
        final events = [event('1'), event('2')];
        when(
          () => mockRepository.calendarEventsAssociationsAssociationIdGet(
            associationId: any(named: 'associationId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), events),
        );

        final result = await container
            .read(associationEventsListProvider.notifier)
            .loadAssociationEventList('asso-1');

        expect(result.value, events);
        expect(
          container.read(associationEventsListProvider.notifier).allNews.value,
          events,
        );
      });

      test(
        'loadAssociationEventList flags the error when the call fails',
        () async {
          when(
            () => mockRepository.calendarEventsAssociationsAssociationIdGet(
              associationId: any(named: 'associationId'),
            ),
          ).thenThrow(Exception('network down'));

          final result = await container
              .read(associationEventsListProvider.notifier)
              .loadAssociationEventList('asso-1');

          expect(result, isA<AsyncError<List<EventCompleteTicketUrl>>>());
        },
      );

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(
          () => mockRepository.calendarEventsAssociationsAssociationIdGet(
            associationId: any(named: 'associationId'),
          ),
        ).thenThrow(error);

        await expectLater(
          container
              .read(associationEventsListProvider.notifier)
              .loadAssociationEventList('asso-1'),
          throwsA(same(error)),
        );
      });

      test(
        'updateEvent patches the event and replaces it in the list',
        () async {
          final gala = event('1');
          when(() => mockRepository.feedNewsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), <News>[]),
          );
          when(
            () => mockRepository.calendarEventsAssociationsAssociationIdGet(
              associationId: any(named: 'associationId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), [gala]),
          );
          final notifier = container.read(
            associationEventsListProvider.notifier,
          );
          await notifier.loadAssociationEventList('asso-1');

          when(
            () => mockRepository.calendarEventsEventIdPatch(
              eventId: any(named: 'eventId'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async =>
                chopper.Response<void>(http.Response('body', 200), null),
          );

          final renamed = gala.copyWith(name: 'Gala 2026');
          final result = await notifier.updateEvent(renamed);

          expect(result, isTrue);
          expect(container.read(associationEventsListProvider).value, [
            renamed,
          ]);
        },
      );

      test(
        'updateEvent keeps the previous list when the patch fails',
        () async {
          final gala = event('1');
          when(
            () => mockRepository.calendarEventsAssociationsAssociationIdGet(
              associationId: any(named: 'associationId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), [gala]),
          );
          final notifier = container.read(
            associationEventsListProvider.notifier,
          );
          await notifier.loadAssociationEventList('asso-1');

          when(
            () => mockRepository.calendarEventsEventIdPatch(
              eventId: any(named: 'eventId'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<void>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );

          final result = await notifier.updateEvent(gala.copyWith(name: 'X'));

          expect(result, isFalse);
          expect(container.read(associationEventsListProvider).value, [gala]);
        },
      );

      test(
        'deleteEvent keeps the event in place (update replaces by key) and rethrows tokenExpire',
        () async {
          final gala = event('1');
          final party = event('2');
          when(
            () => mockRepository.calendarEventsAssociationsAssociationIdGet(
              associationId: any(named: 'associationId'),
            ),
          ).thenAnswer(
            (_) async =>
                chopper.Response(http.Response('body', 200), [gala, party]),
          );
          final notifier = container.read(
            associationEventsListProvider.notifier,
          );
          await notifier.loadAssociationEventList('asso-1');

          when(
            () => mockRepository.calendarEventsEventIdDelete(
              eventId: any(named: 'eventId'),
            ),
          ).thenAnswer(
            (_) async =>
                chopper.Response<void>(http.Response('body', 200), null),
          );

          final result = await notifier.deleteEvent(gala);

          expect(result, isTrue);
          // deleteEvent is built on ListNotifierAPI.update, which replaces the
          // entry with the same key instead of removing it: after deleting
          // `gala` the list still holds both events, gala replaced by itself.
          // Documented as-is; a true removal would need ListNotifierAPI.delete.
          expect(container.read(associationEventsListProvider).value, [
            gala,
            party,
          ]);

          // A delete is also a ListNotifierAPI.update, so a token expiry is
          // rethrown for the session handler.
          final error = AppException(ErrorType.tokenExpire, 'expired');
          when(
            () => mockRepository.calendarEventsEventIdDelete(
              eventId: any(named: 'eventId'),
            ),
          ).thenThrow(error);

          await expectLater(notifier.deleteEvent(party), throwsA(same(error)));
        },
      );
    });
  });
}
