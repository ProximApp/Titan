import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/user_association_membership.dart';

class UserAssociationMembershipNotifier
    extends Notifier<UserAssociationMembership> {
  @override
  UserAssociationMembership build() {
    return UserAssociationMembership.empty();
  }

  void setUserAssociationMembership(
    UserAssociationMembership userUserAssociationMembership,
  ) {
    state = userUserAssociationMembership;
  }
}

final userAssociationMembershipProvider =
    NotifierProvider<
      UserAssociationMembershipNotifier,
      UserAssociationMembership
    >(() => UserAssociationMembershipNotifier());
