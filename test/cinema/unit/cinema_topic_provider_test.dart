import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/cinema/providers/cinema_topic_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  group('CinemaTopicsProvider', () {
    test('getTopics loads the subscription list', () async {
      when(() => repo.notificationTopicsGet())
          .thenAnswer((_) async => repo.okList<TopicUser>());
      final notifier = container.read(cinemaTopicsProvider.notifier);
      final state = await notifier.getTopics();
      expect(state.value, isEmpty);
    });

    test('subscribeSession posts the topic subscription', () async {
      final notifier = container.read(cinemaTopicsProvider.notifier);
      final topic = TopicUser.empty().copyWith(id: 't-1');
      // update() looks the topic up inside the loaded list, so it has to be
      // there for the subscription to be able to replace it.
      notifier.state = AsyncValue.data([topic]);
      when(() => repo.notificationTopicsTopicIdSubscribePost(topicId: 't-1'))
          .thenAnswer((_) async => repo.okVoid());

      expect(await notifier.subscribeSession(topic), isTrue);
    });

    test('subscribeSession reports false when the post fails', () async {
      final notifier = container.read(cinemaTopicsProvider.notifier);
      final topic = TopicUser.empty().copyWith(id: 't-1');
      notifier.state = AsyncValue.data([]);
      when(() => repo.notificationTopicsTopicIdSubscribePost(topicId: 't-1'))
          .thenAnswer((_) async => repo.fail<void>(500));

      expect(await notifier.subscribeSession(topic), isFalse);
    });

    test('unsubscribeSession posts the topic unsubscription', () async {
      final notifier = container.read(cinemaTopicsProvider.notifier);
      final topic = TopicUser.empty().copyWith(id: 't-1');
      notifier.state = AsyncValue.data([topic]);
      when(() => repo.notificationTopicsTopicIdUnsubscribePost(topicId: 't-1'))
          .thenAnswer((_) async => repo.okVoid());

      expect(await notifier.unsubscribeSession(topic), isTrue);
    });

    test('unsubscribeSession reports false when the post fails', () async {
      final notifier = container.read(cinemaTopicsProvider.notifier);
      final topic = TopicUser.empty().copyWith(id: 't-1');
      notifier.state = AsyncValue.data([topic]);
      when(() => repo.notificationTopicsTopicIdUnsubscribePost(topicId: 't-1'))
          .thenAnswer((_) async => repo.fail<void>(500));

      expect(await notifier.unsubscribeSession(topic), isFalse);
    });

    test('toggleSubscription unsubscribes a subscribed topic', () async {
      final notifier = container.read(cinemaTopicsProvider.notifier);
      final topic = TopicUser.empty().copyWith(id: 't-1');
      notifier.state = AsyncValue.data([topic]);
      when(() => repo.notificationTopicsTopicIdUnsubscribePost(topicId: 't-1'))
          .thenAnswer((_) async => repo.okVoid());

      expect(await notifier.toggleSubscription(topic), isTrue);
    });

    test(
      'toggleSubscription subscribes a topic the user does not follow',
      () async {
        final notifier = container.read(cinemaTopicsProvider.notifier);
        // The loaded list holds every topic with its subscription flag baked
        // into the equality: flipping isUserSubscribed makes it the
        // not-followed variant, and update() still finds the row by id.
        final notFollowed = TopicUser.empty().copyWith(
          id: 't-2',
          name: 'Cinema',
          isUserSubscribed: false,
        );
        final topic = notFollowed.copyWith(isUserSubscribed: true);
        notifier.state = AsyncValue.data([notFollowed]);
        when(() => repo.notificationTopicsTopicIdSubscribePost(topicId: 't-2'))
            .thenAnswer((_) async => repo.okVoid());

        expect(await notifier.toggleSubscription(topic), isTrue);
        expect(notifier.state.value!.single.isUserSubscribed, isTrue);
      },
    );

    test('toggleSubscription reports false outside a loaded list', () async {
      final notifier = container.read(cinemaTopicsProvider.notifier);
      notifier.state = const AsyncValue.loading();
      expect(
        await notifier.toggleSubscription(
          TopicUser.empty().copyWith(id: 't-1'),
        ),
        isFalse,
      );
    });
  });
}
