import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/flappybird/class/score.dart';
import 'package:titan/flappybird/repositories/score_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ScoreListNotifier extends ListNotifier<Score> {
  ScoreRepository get scoreRepository => ref.watch(scoreRepositoryProvider);

  @override
  AsyncValue<List<Score>> build() {
    return const AsyncLoading();
  }

  Future<AsyncValue<List<Score>>> getLeaderboard() async {
    return await loadList(scoreRepository.getLeaderboard);
  }

  Future<bool> createScore(Score score) async {
    return await add(scoreRepository.createScore, score);
  }
}

final scoreListProvider =
    NotifierProvider<ScoreListNotifier, AsyncValue<List<Score>>>(
      ScoreListNotifier.new,
    );
