import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/vote/class/voter.dart';

class VoterRepository extends Repository {
  @override
  // ignore: overridden_fields
  final ext = "campaign/voters";

  Future<bool> deleteVoter(String voterId) async {
    return await delete("/$voterId");
  }

  Future<Voter> createVoter(Voter voter) async {
    return Voter.fromJson(await create(voter.toJson()));
  }

  Future<List<Voter>> getVoters() async {
    return (await getList()).map((e) => Voter.fromJson(e)).toList();
  }
}

final voterRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return VoterRepository()..setToken(token);
});
