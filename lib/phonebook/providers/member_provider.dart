import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/phonebook/class/member.dart';

final memberProvider = NotifierProvider<MemberProvider, Member>(
  MemberProvider.new,
);

class MemberProvider extends Notifier<Member> {
  @override
  Member build() {
    return Member.empty();
  }

  void setMember(Member i) {
    state = i;
  }
}
