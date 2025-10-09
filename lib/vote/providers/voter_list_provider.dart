import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';
import 'package:titan/vote/class/voter.dart';
import 'package:titan/vote/repositories/voter_repository.dart';

class VoterListNotifier extends ListNotifier<Voter> {
  VoterRepository get voterRepository => ref.watch(voterRepositoryProvider);

  @override
  AsyncValue<List<Voter>> build() {
    tokenExpireWrapperAuth(ref, () async {
      await loadVoterList();
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Voter>>> loadVoterList() async {
    return await loadList(voterRepository.getVoters);
  }

  Future<bool> addVoter(Voter voter) async {
    return await add(voterRepository.createVoter, voter);
  }

  Future<bool> deleteVoter(Voter voter) async {
    return await delete(
      voterRepository.deleteVoter,
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
