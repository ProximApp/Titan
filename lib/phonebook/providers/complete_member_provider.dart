import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';
import 'package:titan/tools/repository/repository.dart';

class CompleteMemberProvider extends Notifier<MemberComplete> {
  Openapi get memberRepository => ref.watch(repositoryProvider);

  @override
  MemberComplete build() {
    return EmptyModels.empty<MemberComplete>();
  }

  void setCompleteMember(MemberComplete i) {
    state = i;
  }

  void setMember(MemberComplete i) {
    state = i;
  }

  Future<bool> loadMemberComplete() async {
    try {
      final data = await memberRepository.phonebookMemberUserIdGet(
        userId: state.id,
      );
      if (data.isSuccessful) {
        state = data.body!;
        return true;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final completeMemberProvider =
    NotifierProvider<CompleteMemberProvider, MemberComplete>(
      CompleteMemberProvider.new,
    );
