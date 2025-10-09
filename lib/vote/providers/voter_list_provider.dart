import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';
import 'package:titan/vote/class/voter.dart';
import 'package:titan/vote/repositories/voter_repository.dart';

class VoterListNotifier extends ListNotifier<Voter> {
  final VoterRepository _voterRepository = VoterRepository();

  @override
  AsyncValue<List<Voter>> build() {
    final token = ref.watch(tokenProvider);
    _voterRepository.setToken(token);
    tokenExpireWrapperAuth(ref, () async {
      await loadVoterList();
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Voter>>> loadVoterList() async {
    return await loadList(_voterRepository.getVoters);
  }

  Future<bool> addVoter(Voter voter) async {
    return await add(_voterRepository.createVoter, voter);
  }

  Future<bool> deleteVoter(Voter voter) async {
    return await delete(
      _voterRepository.deleteVoter,
      (voters, voter) => voters..removeWhere((p) => p.groupId == voter.groupId),
      voter.groupId,
      voter,
    );
  }
}

final voterListProvider =
    NotifierProvider<VoterListNotifier, AsyncValue<List<Voter>>>(
      VoterListNotifier.new,
    );
