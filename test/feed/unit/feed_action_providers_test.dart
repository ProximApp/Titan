import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/feed/providers/event_image_provider.dart';
import 'package:titan/feed/providers/event_provider.dart';
import 'package:titan/feed/providers/event_ticket_url_provider.dart';
import 'package:titan/feed/providers/news_image_provider.dart';
import 'package:titan/feed/providers/news_images_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/repository/repository.dart';

class MockFeedRepository extends Mock implements Openapi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feed action providers', () {
    late MockFeedRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockFeedRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('EventNotifier', () {
      test(
        'build leaves the state loading: its fakeLoad() runs during build and '
        'is overwritten by the returned loading value',
        () async {
          container.read(eventProvider.notifier);
          await Future<void>.delayed(Duration.zero);

          // Documented as-is: build() returns AsyncLoading after fakeLoad()
          // set data, and build()'s return value wins.
          expect(container.read(eventProvider), isA<AsyncLoading>());
        },
      );

      test('fakeLoad primes the state with an empty event', () {
        final notifier = container.read(eventProvider.notifier);

        notifier.fakeLoad();

        final state = container.read(eventProvider);
        expect(state, isA<AsyncData<EventCompleteTicketUrl>>());
        expect(state.value, EventCompleteTicketUrl.empty());
      });

      test('setEvent exposes the given event', () {
        final notifier = container.read(eventProvider.notifier);
        final gala = EventCompleteTicketUrl.empty().copyWith(id: 'e-1');

        notifier.setEvent(gala);

        expect(container.read(eventProvider).value, gala);
      });

      test('addEvent exposes the created event', () async {
        final created = EventCompleteTicketUrl.empty().copyWith(id: 'e-1');
        when(
          () => mockRepository.calendarEventsPost(body: any(named: 'body')),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 201), created),
        );

        final result = await container
            .read(eventProvider.notifier)
            .addEvent(EventBaseCreation.empty());

        expect(result.value, created);
        expect(container.read(eventProvider).value, created);
      });

      test('addEvent flags the error when the backend rejects it', () async {
        when(
          () => mockRepository.calendarEventsPost(body: any(named: 'body')),
        ).thenAnswer(
          (_) async => chopper.Response<EventCompleteTicketUrl>(
            http.Response('invalid', 400),
            null,
            error: 'invalid',
          ),
        );

        final result = await container
            .read(eventProvider.notifier)
            .addEvent(EventBaseCreation.empty());

        expect(result, isA<AsyncError<EventCompleteTicketUrl>>());
        expect(
          container.read(eventProvider),
          isA<AsyncError<EventCompleteTicketUrl>>(),
        );
      });

      test(
        'addEvent rethrows AppException.tokenExpire after flagging it',
        () async {
          final error = AppException(ErrorType.tokenExpire, 'expired');
          when(
            () => mockRepository.calendarEventsPost(body: any(named: 'body')),
          ).thenThrow(error);

          await expectLater(
            container
                .read(eventProvider.notifier)
                .addEvent(EventBaseCreation.empty()),
            throwsA(same(error)),
          );
          // SingleNotifierAPI.load writes the error state before rethrowing,
          // unlike ListNotifierAPI.loadList which leaves the previous state.
          expect(
            container.read(eventProvider),
            isA<AsyncError<EventCompleteTicketUrl>>(),
          );
        },
      );
    });

    group('TicketUrlNotifier', () {
      test('starts in the loading state', () {
        expect(container.read(ticketUrlProvider), isA<AsyncLoading>());
      });

      test('getTicketUrl exposes the ticket url', () async {
        final ticketUrl = EventTicketUrl(ticketUrl: 'https://example.com/t/1');
        when(
          () => mockRepository.calendarEventsEventIdTicketUrlGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), ticketUrl),
        );

        final result = await container
            .read(ticketUrlProvider.notifier)
            .getTicketUrl('event-1');

        expect(result.value, ticketUrl);
        expect(container.read(ticketUrlProvider).value, ticketUrl);
      });

      test('getTicketUrl flags the error when the call fails', () async {
        when(
          () => mockRepository.calendarEventsEventIdTicketUrlGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenThrow(Exception('network down'));

        final result = await container
            .read(ticketUrlProvider.notifier)
            .getTicketUrl('event-1');

        expect(result, isA<AsyncError<EventTicketUrl>>());
      });
    });

    group('EventImageNotifier', () {
      test('addEventImage uploads the bytes and shows the new image', () async {
        final bytes = Uint8List.fromList([1, 2, 3]);
        when(
          () => mockRepository.calendarEventsEventIdImagePost(
            eventId: any(named: 'eventId'),
            image: any(named: 'image'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 201), null),
        );

        final result = await container
            .read(eventImageProvider.notifier)
            .addEventImage('event-1', bytes);

        expect(result, isTrue);
        final image = container.read(eventImageProvider).value!;
        expect((image.image as MemoryImage).bytes, bytes);
      });

      test('getEventImage shows the fetched image', () async {
        final bytes = Uint8List.fromList([4, 5, 6]);
        when(
          () => mockRepository.calendarEventsEventIdImageGet(
            eventId: any(named: 'eventId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<List<int>>(
            http.Response.bytes(bytes, 200),
            bytes,
          ),
        );

        // getEventImage is declared `void ... async`, so it can only be
        // awaited through pumping the microtask queue.
        container.read(eventImageProvider.notifier).getEventImage('e-1');
        await Future<void>.delayed(Duration.zero);

        final image = container.read(eventImageProvider).value!;
        expect((image.image as MemoryImage).bytes, bytes);
      });

      test(
        'getEventImage falls back to the titan logo when the file is missing',
        () async {
          // A 404 has no decodable body, so fileBytes reads as empty and the
          // notifier swaps in the placeholder asset instead of crashing on
          // Image.memory.
          when(
            () => mockRepository.calendarEventsEventIdImageGet(
              eventId: any(named: 'eventId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<List<int>>(
              http.Response('{"detail": "File does not exist"}', 404),
              [],
              error: 'File does not exist',
            ),
          );

          container.read(eventImageProvider.notifier).getEventImage('e-1');
          await Future<void>.delayed(Duration.zero);

          final image = container.read(eventImageProvider).value!;
          expect(image.image, isA<AssetImage>());
          expect((image.image as AssetImage).assetName, getTitanLogo());
        },
      );
    });

    group('NewsImageNotifier', () {
      test(
        'getNewsImage caches the fetched image in the news images map',
        () async {
          final bytes = Uint8List.fromList([7, 8, 9]);
          when(
            () => mockRepository.feedNewsNewsIdImageGet(
              newsId: any(named: 'newsId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<List<int>>(
              http.Response.bytes(bytes, 200),
              bytes,
            ),
          );

          final image = await container
              .read(newsImageProvider.notifier)
              .getNewsImage('news-1');

          expect((image.image as MemoryImage).bytes, bytes);
          final cached = container.read(newsImagesProvider)['news-1'];
          expect(cached, isA<AsyncData<List<Image>>>());
          expect(cached!.value, [image]);
        },
      );

      test(
        'getNewsImage caches the titan logo when the file is missing',
        () async {
          when(
            () => mockRepository.feedNewsNewsIdImageGet(
              newsId: any(named: 'newsId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<List<int>>(
              http.Response('{"detail": "File does not exist"}', 404),
              [],
              error: 'File does not exist',
            ),
          );

          final image = await container
              .read(newsImageProvider.notifier)
              .getNewsImage('news-1');

          expect((image.image as AssetImage).assetName, getTitanLogo());
          expect(container.read(newsImagesProvider)['news-1']!.value, [image]);
        },
      );
    });
  });
}
