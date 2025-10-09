import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class CinemaTopicRepository extends Repository {
  @override
  // ignore: overridden_fields
  final ext = 'notification/';
  final prefix = "cinema_";

  Future<bool> subscribeSession(String topic) async {
    return await create({}, suffix: "topics/$prefix$topic/subscribe");
  }

  Future<bool> unsubscribeSession(String topic) async {
    return await create({}, suffix: "topics/$prefix$topic/unsubscribe");
  }

  Future<List<String>> getCinemaTopics() async {
    return List<String>.from(
      (await getList(
        suffix: "topics/${prefix.substring(0, prefix.length - 1)}",
      )).map((x) => x.split(prefix)[1]),
    );
  }
}

final cinemaTopicRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return CinemaTopicRepository()..setToken(token);
});
