import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/flappybird/class/score.dart';
import 'package:titan/flappybird/repositories/score_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class ScoreListNotifier extends SingleNotifier<Score> {
  final ScoreRepository _scoreRepository = ScoreRepository();

  @override
  AsyncValue<Score> build() {
    final token = ref.watch(tokenProvider);
    _scoreRepository.setToken(token);
    return const AsyncLoading();
  }

  Future<AsyncValue<Score>> getLeaderBoardPosition() async {
    return await load(_scoreRepository.getLeaderBoardPosition);
  }
}

final userScoreProvider =
    NotifierProvider<ScoreListNotifier, AsyncValue<Score>>(
      ScoreListNotifier.new,
    );
