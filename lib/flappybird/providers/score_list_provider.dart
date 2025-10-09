import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/flappybird/class/score.dart';
import 'package:titan/flappybird/repositories/score_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ScoreListNotifier extends ListNotifier<Score> {
  final ScoreRepository _scoreRepository = ScoreRepository();

  @override
  AsyncValue<List<Score>> build() {
    final token = ref.watch(tokenProvider);
    _scoreRepository.setToken(token);
    return const AsyncLoading();
  }

  Future<AsyncValue<List<Score>>> getLeaderboard() async {
    return await loadList(_scoreRepository.getLeaderboard);
  }

  Future<bool> createScore(Score score) async {
    return await add(_scoreRepository.createScore, score);
  }
}

final scoreListProvider =
    NotifierProvider<ScoreListNotifier, AsyncValue<List<Score>>>(
      ScoreListNotifier.new,
    );
