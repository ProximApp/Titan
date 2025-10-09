import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/phonebook/class/complete_member.dart';
import 'package:titan/phonebook/class/member.dart';
import 'package:titan/phonebook/repositories/member_repository.dart';

class CompleteMemberProvider extends Notifier<CompleteMember> {
  MemberRepository get memberRepository => ref.watch(memberRepositoryProvider);

  @override
  CompleteMember build() {
    return CompleteMember.empty();
  }

  void setCompleteMember(CompleteMember i) {
    state = i;
  }

  void setMember(Member i) {
    state = state.copyWith(member: i);
  }

  Future<bool> loadMemberComplete() async {
    try {
      final data = await memberRepository.getCompleteMember(state.member.id);
      state = state.copyWith(member: data.member, membership: data.memberships);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final completeMemberProvider =
    NotifierProvider<CompleteMemberProvider, CompleteMember>(
      CompleteMemberProvider.new,
    );
