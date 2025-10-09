import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/cinema/repositories/cinema_topic_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class CinemaTopicsProvider extends ListNotifier<String> {
  CinemaTopicRepository get cinemaTopicRepository =>
      ref.watch(cinemaTopicRepositoryProvider);

  @override
  AsyncValue<List<String>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<String>>> getTopics() async {
    return await loadList(cinemaTopicRepository.getCinemaTopics);
  }

  Future<bool> subscribeSession(String topic) async {
    return await update(
      cinemaTopicRepository.subscribeSession,
      (listT, t) => listT..add(t),
      topic,
    );
  }

  Future<bool> unsubscribeSession(String topic) async {
    return await update(
      cinemaTopicRepository.unsubscribeSession,
      (listT, t) => listT..remove(t),
      topic,
    );
  }

  Future<bool> toggleSubscription(String topic) async {
    return state.maybeWhen(
      data: (data) {
        if (data.contains(topic)) {
          return unsubscribeSession(topic);
        }
        return subscribeSession(topic);
      },
      orElse: () => false,
    );
  }
}

final cinemaTopicsProvider =
    NotifierProvider<CinemaTopicsProvider, AsyncValue<List<String>>>(
      CinemaTopicsProvider.new,
    );
