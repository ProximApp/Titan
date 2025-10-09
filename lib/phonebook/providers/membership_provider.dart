import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/phonebook/class/membership.dart';

final membershipProvider = NotifierProvider<MembershipProvider, Membership>(
  () => MembershipProvider(),
);

class MembershipProvider extends Notifier<Membership> {
  @override
  Membership build() {
    return Membership.empty();
  }

  void setMembership(Membership i) {
    state = i;
  }
}
