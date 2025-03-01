import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class VoterListNotifier extends ListNotifierAPI<VoterGroup> {
  Openapi get voterRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<VoterGroup>> build() {
    tokenExpireWrapperAuth(ref, () async {
      await loadVoterList();
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<VoterGroup>>> loadVoterList() async {
    return await loadList(voterRepository.campaignVotersGet);
  }

  Future<bool> addVoter(VoterGroup voter) async {
    return await add(
      () => voterRepository.campaignVotersPost(body: voter),
      voter,
    );
  }

  Future<bool> deleteVoter(VoterGroup voter) async {
    return await delete(
      () => voterRepository.campaignVotersGroupIdDelete(groupId: voter.groupId),
      (voter) => voter.groupId,
      voter.groupId,
    );
  }
}

final voterListProvider =
    NotifierProvider<VoterListNotifier, AsyncValue<List<VoterGroup>>>(
      VoterListNotifier.new,
    );
