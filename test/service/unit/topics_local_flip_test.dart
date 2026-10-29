import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/service/providers/topic_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// The `TopicsProvider` branches the other tests never reach: the three
/// `maybeWhen(orElse:)` arms (state still loading — the provider boots that
/// way, and `build()`'s `getTopics()` is unawaited), the local-only
/// `fakeUnsubscribeTopic` update, and `fakeToggleSubscription`'s unsubscribe
/// side. The main test file covers only the data-state subscribe and
/// unsubscribe round trips.
void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  final topic = TopicUser.empty().copyWith(id: 't-1', name: 'News');

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  /// The notifier is created only AFTER its stub exists: reading it runs
  /// `build()`, which fires the list call unawaited.
  TopicsProvider notifier() => container.read(topicsProvider.notifier);

  test(
    'the orElse arms answer false while the list is still loading',
    () async {
      // A list call that never settles keeps the state at `loading`.
      when(() => repo.notificationTopicsGet()).thenAnswer(
        (_) => Completer<chopper.Response<List<TopicUser>>>().future,
      );

      final subject = notifier();

      expect(await subject.toggleSubscription(topic), isFalse);
      expect(await subject.fakeToggleSubscription(topic), isFalse);
      await subject.subscribeAll();
      expect(subject.state.isLoading, isTrue);
      // Still loading: none of those arms issued a POST.
      verifyNever(
        () => repo.notificationTopicsTopicIdSubscribePost(
          topicId: any(named: 'topicId'),
        ),
      );
    },
  );

  test('fakeUnsubscribeTopic flips the local list without a POST', () async {
    when(() => repo.notificationTopicsGet())
        .thenAnswer((_) async => repo.okList<TopicUser>());

    final subject = notifier();
    await subject.getTopics();
    // A same-id entry: `localUpdate` replaces it in place rather than
    // removing it, so the swap is what makes the update observable.
    subject.state = AsyncValue.data([topic.copyWith(name: 'Old name')]);

    expect(await subject.fakeUnsubscribeTopic(topic), isTrue);
    expect(subject.state.value, hasLength(1));
    expect(subject.state.value!.single.name, 'News');
    // No unsubscribe stub exists: a network call would have thrown.
    verifyNever(
      () => repo.notificationTopicsTopicIdUnsubscribePost(
        topicId: any(named: 'topicId'),
      ),
    );
  });

  test('fakeToggleSubscription unsubscribes a topic the list holds', () async {
    when(() => repo.notificationTopicsGet())
        .thenAnswer((_) async => repo.okList<TopicUser>());

    final subject = notifier();
    await subject.getTopics();
    subject.state = AsyncValue.data([topic.copyWith(name: 'Old name')]);

    expect(await subject.fakeToggleSubscription(topic), isTrue);
    expect(subject.state.value, hasLength(1));
    expect(subject.state.value!.single.name, 'News');
  });
}
