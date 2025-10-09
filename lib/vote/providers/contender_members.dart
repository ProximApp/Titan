import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/vote/class/members.dart';

class ContenderMembersProvider extends Notifier<List<Member>> {
  @override
  List<Member> build() => [];

  Future<bool> addMember(Member m) async {
    var copy = state.toList();
    if (!copy.contains(m)) {
      copy.add(m);
      state = copy;
      return true;
    }
    return false;
  }

  void removeMember(Member m) {
    var copy = state.toList();
    copy.remove(m);
    state = copy;
  }

  void clearMembers() {
    state = [];
  }

  void setMembers(List<Member> members) {
    state = members;
  }
}

final contenderMembersProvider =
    NotifierProvider<ContenderMembersProvider, List<Member>>(
      ContenderMembersProvider.new,
    );
