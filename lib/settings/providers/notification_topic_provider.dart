import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/settings/class/notification_topic.dart';
import 'package:titan/settings/repositories/notification_topic_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class NotificationTopicNotifier extends ListNotifier<NotificationTopic> {
  final NotificationTopicRepository notificationTopicRepository =
      NotificationTopicRepository();

  @override
  AsyncValue<List<NotificationTopic>> build() {
    final token = ref.watch(tokenProvider);
    notificationTopicRepository.setToken(token);
    loadNotificationTopicList();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<NotificationTopic>>>
  loadNotificationTopicList() async {
    return await loadList(
      () async => notificationTopicRepository.getAllNotificationTopic(),
    );
  }

  Future<bool> toggleSubscription(NotificationTopic topic) async {
    return await update(
      topic.isUserSubscribed
          ? notificationTopicRepository.unsubscribeTopic
          : notificationTopicRepository.subscribeTopic,
      (topics, topic) {
        topics[topics.indexWhere((t) => t.id == topic.id)] = topic.copyWith(
          isUserSubscribed: !topic.isUserSubscribed,
        );
        return topics;
      },
      topic,
    );
  }
}

final notificationTopicListProvider =
    NotifierProvider<
      NotificationTopicNotifier,
      AsyncValue<List<NotificationTopic>>
    >(NotificationTopicNotifier.new);
