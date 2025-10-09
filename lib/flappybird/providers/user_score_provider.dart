import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/flappybird/class/score.dart';
import 'package:titan/flappybird/repositories/score_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class UserScoreNotifier extends SingleNotifier<Score> {
  ScoreRepository get scoreRepository => ref.watch(scoreRepositoryProvider);

  @override
  AsyncValue<Score> build() {
    return const AsyncLoading();
  }

  Future<AsyncValue<Score>> getLeaderBoardPosition() async {
    return await load(scoreRepository.getLeaderBoardPosition);
  }
}

final userScoreProvider =
    NotifierProvider<UserScoreNotifier, AsyncValue<Score>>(
      UserScoreNotifier.new,
    );
