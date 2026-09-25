import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/settings/providers/logs_provider.dart';
import 'package:titan/settings/providers/notification_topic_provider.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/tools/repository/repository.dart';

class MockOpenapiRepository extends Mock implements Openapi {}

class MockLogger extends Mock implements Logger {}

Log log(String message, {LogLevel level = LogLevel.info}) =>
    Log(message: message, level: level);

void main() {
  group('Settings list providers', () {
    late MockOpenapiRepository mockRepository;
    late MockLogger mockLogger;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockOpenapiRepository();
      mockLogger = MockLogger();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          // Logger's constructor kicks off a real file-IO init, so it always
          // has to be replaced by a mock in tests.
          loggerProvider.overrideWithValue(mockLogger),
        ],
      );
    });

    tearDown(() => container.dispose());

    group('LogsProvider', () {
      test('starts in the loading state', () {
        expect(container.read(logsProvider), isA<AsyncLoading<List<Log>>>());
      });

      test('getLogs exposes the logger output', () async {
        final logs = [log('started', level: LogLevel.debug), log('boom')];
        when(() => mockLogger.getLogs()).thenReturn(logs);

        final result = await container.read(logsProvider.notifier).getLogs();

        expect(result.value, logs);
      });

      test('getLogs flags the error when the logger throws', () async {
        when(() => mockLogger.getLogs()).thenThrow(Exception('disk full'));

        final result = await container.read(logsProvider.notifier).getLogs();

        expect(result, isA<AsyncError<List<Log>>>());
      });

      test('deleteLogs clears the logs and empties the list', () async {
        final logs = [log('started'), log('boom')];
        when(() => mockLogger.getLogs()).thenReturn(logs);
        final notifier = container.read(logsProvider.notifier);
        await notifier.getLogs();

        when(() => mockLogger.clearLogs()).thenReturn(null);

        final result = await notifier.deleteLogs();

        expect(result, isTrue);
        verify(() => mockLogger.clearLogs()).called(1);
        expect(container.read(logsProvider).value, isEmpty);
      });

      test(
        'deleteLogs fails without touching the list when in error state',
        () async {
          when(() => mockLogger.getLogs()).thenThrow(Exception('disk full'));
          final notifier = container.read(logsProvider.notifier);
          await notifier.getLogs();

          final result = await notifier.deleteLogs();

          expect(result, isFalse);
          verifyNever(() => mockLogger.clearLogs());
        },
      );
    });

    group('NotificationLogsProvider', () {
      test('getLogs exposes the notification log output', () async {
        final logs = [log('{"title": "Hello"}', level: LogLevel.notification)];
        when(() => mockLogger.getNotificationLogs()).thenReturn(logs);

        final result = await container
            .read(notificationLogsProvider.notifier)
            .getLogs();

        expect(result.value, logs);
      });

      test('deleteLogs clears only the notification logs', () async {
        when(
          () => mockLogger.getNotificationLogs(),
        ).thenReturn([log('n', level: LogLevel.notification)]);
        final notifier = container.read(notificationLogsProvider.notifier);
        await notifier.getLogs();

        when(() => mockLogger.clearNotificationLogs()).thenReturn(null);

        final result = await notifier.deleteLogs();

        expect(result, isTrue);
        verify(() => mockLogger.clearNotificationLogs()).called(1);
        verifyNever(() => mockLogger.clearLogs());
        expect(container.read(notificationLogsProvider).value, isEmpty);
      });
    });

    group('NotificationTopicNotifier', () {
      TopicUser topic(String id, bool subscribed) =>
          TopicUser.empty().copyWith(id: id, isUserSubscribed: subscribed);

      test('build fetches the topic list right away', () async {
        final topics = [topic('1', false)];
        when(() => mockRepository.notificationTopicsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), topics),
        );

        container.read(notificationTopicListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(notificationTopicListProvider).value, topics);
      });

      test('build flags the error when the fetch fails', () async {
        when(
          () => mockRepository.notificationTopicsGet(),
        ).thenThrow(Exception('network down'));

        container.read(notificationTopicListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(notificationTopicListProvider),
          isA<AsyncError<List<TopicUser>>>(),
        );
      });

      test(
        'toggleSubscription subscribes an unsubscribed topic and flips it locally',
        () async {
          final unsubscribed = topic('1', false);
          when(() => mockRepository.notificationTopicsGet()).thenAnswer(
            (_) async =>
                chopper.Response(http.Response('body', 200), [unsubscribed]),
          );
          final notifier = container.read(
            notificationTopicListProvider.notifier,
          );
          await notifier.loadNotificationTopicList();

          when(
            () => mockRepository.notificationTopicsTopicIdSubscribePost(
              topicId: any(named: 'topicId'),
            ),
          ).thenAnswer(
            (_) async =>
                chopper.Response<void>(http.Response('body', 200), null),
          );

          final result = await notifier.toggleSubscription(unsubscribed);

          expect(result, isTrue);
          verify(
            () => mockRepository.notificationTopicsTopicIdSubscribePost(
              topicId: '1',
            ),
          ).called(1);
          verifyNever(
            () => mockRepository.notificationTopicsTopicIdUnsubscribePost(
              topicId: any(named: 'topicId'),
            ),
          );
          expect(container.read(notificationTopicListProvider).value, [
            unsubscribed.copyWith(isUserSubscribed: true),
          ]);
        },
      );

      test(
        'toggleSubscription unsubscribes a subscribed topic and flips it locally',
        () async {
          final subscribed = topic('1', true);
          when(() => mockRepository.notificationTopicsGet()).thenAnswer(
            (_) async =>
                chopper.Response(http.Response('body', 200), [subscribed]),
          );
          final notifier = container.read(
            notificationTopicListProvider.notifier,
          );
          await notifier.loadNotificationTopicList();

          when(
            () => mockRepository.notificationTopicsTopicIdUnsubscribePost(
              topicId: any(named: 'topicId'),
            ),
          ).thenAnswer(
            (_) async =>
                chopper.Response<void>(http.Response('body', 200), null),
          );

          final result = await notifier.toggleSubscription(subscribed);

          expect(result, isTrue);
          verify(
            () => mockRepository.notificationTopicsTopicIdUnsubscribePost(
              topicId: '1',
            ),
          ).called(1);
          verifyNever(
            () => mockRepository.notificationTopicsTopicIdSubscribePost(
              topicId: any(named: 'topicId'),
            ),
          );
          expect(container.read(notificationTopicListProvider).value, [
            subscribed.copyWith(isUserSubscribed: false),
          ]);
        },
      );

      test(
        'toggleSubscription keeps the old subscription when the endpoint fails',
        () async {
          final unsubscribed = topic('1', false);
          when(() => mockRepository.notificationTopicsGet()).thenAnswer(
            (_) async =>
                chopper.Response(http.Response('body', 200), [unsubscribed]),
          );
          final notifier = container.read(
            notificationTopicListProvider.notifier,
          );
          await notifier.loadNotificationTopicList();

          when(
            () => mockRepository.notificationTopicsTopicIdSubscribePost(
              topicId: any(named: 'topicId'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<void>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );

          final result = await notifier.toggleSubscription(unsubscribed);

          expect(result, isFalse);
          expect(container.read(notificationTopicListProvider).value, [
            unsubscribed,
          ]);
        },
      );

      test('toggleSubscription rethrows AppException.tokenExpire', () async {
        final unsubscribed = topic('1', false);
        when(() => mockRepository.notificationTopicsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), [unsubscribed]),
        );
        final notifier = container.read(notificationTopicListProvider.notifier);
        await notifier.loadNotificationTopicList();

        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(
          () => mockRepository.notificationTopicsTopicIdSubscribePost(
            topicId: any(named: 'topicId'),
          ),
        ).thenThrow(error);

        await expectLater(
          notifier.toggleSubscription(unsubscribed),
          throwsA(same(error)),
        );
      });
    });
  });
}
