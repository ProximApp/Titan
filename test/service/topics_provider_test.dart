import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/service/providers/topic_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('TopicsProvider', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late TopicsProvider notifier;
    final topic = TopicUser.empty().copyWith(id: 'topic-1', name: 'News');

    setUp(() {
      mockRepository = MockRepository();
      when(() => mockRepository.notificationTopicsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('[]', 200), <TopicUser>[]),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(topicsProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('getTopics loads the topics', () async {
      when(() => mockRepository.notificationTopicsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [topic]),
      );

      final result = await notifier.getTopics();

      expect(result.value, [topic]);
    });

    test('getTopics handles error', () async {
      when(
        () => mockRepository.notificationTopicsGet(),
      ).thenThrow(Exception('topics failed'));

      final result = await notifier.getTopics();

      expect(result, isA<AsyncError<List<TopicUser>>>());
    });

    test('subscribeTopic keeps the topic in the list', () async {
      when(
        () => mockRepository.notificationTopicsTopicIdSubscribePost(
          topicId: 'topic-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([topic]);
      final result = await notifier.subscribeTopic(topic);

      expect(result, true);
      expect(notifier.state.value, [topic]);
    });

    test('unsubscribeTopic keeps the topic in the list', () async {
      when(
        () => mockRepository.notificationTopicsTopicIdUnsubscribePost(
          topicId: 'topic-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([topic]);
      final result = await notifier.unsubscribeTopic(topic);

      expect(result, true);
      expect(notifier.state.value, [topic]);
    });

    test('toggleSubscription unsubscribes when already subscribed', () async {
      when(
        () => mockRepository.notificationTopicsTopicIdUnsubscribePost(
          topicId: 'topic-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([topic]);
      final result = await notifier.toggleSubscription(topic);

      expect(result, true);
      verify(
        () => mockRepository.notificationTopicsTopicIdUnsubscribePost(
          topicId: 'topic-1',
        ),
      ).called(1);
    });

    test('toggleSubscription subscribes the flipped copy by id', () async {
      // Real usage (settings notification toggles): the list holds the topic
      // with isUserSubscribed = false; the flipped copy is not `contains`-equal
      // so the subscribe branch runs, and update() replaces it by id.
      when(
        () => mockRepository.notificationTopicsTopicIdSubscribePost(
          topicId: 'topic-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      final subscribed = topic.copyWith(isUserSubscribed: true);
      notifier.state = AsyncValue.data([topic]);
      final result = await notifier.toggleSubscription(subscribed);

      expect(result, true);
      expect(notifier.state.value, [subscribed]);
      verify(
        () => mockRepository.notificationTopicsTopicIdSubscribePost(
          topicId: 'topic-1',
        ),
      ).called(1);
    });

    test('fake toggles only update the local state', () async {
      final subscribed = topic.copyWith(isUserSubscribed: true);
      notifier.state = AsyncValue.data([topic]);

      await notifier.fakeToggleSubscription(subscribed);
      expect(notifier.state.value, [subscribed]);

      await notifier.fakeToggleSubscription(topic);
      expect(notifier.state.value, [topic]);

      verifyNever(
        () => mockRepository.notificationTopicsTopicIdSubscribePost(
          topicId: any(named: 'topicId'),
        ),
      );
    });

    test('subscribeAll subscribes to every loaded topic', () async {
      final topic2 = TopicUser.empty().copyWith(id: 'topic-2');
      when(
        () => mockRepository.notificationTopicsTopicIdSubscribePost(
          topicId: any(named: 'topicId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([topic, topic2]);
      await notifier.subscribeAll();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => mockRepository.notificationTopicsTopicIdSubscribePost(
          topicId: any(named: 'topicId'),
        ),
      ).called(2);
    });
  });
}
