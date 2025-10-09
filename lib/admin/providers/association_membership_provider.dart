import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/association_membership_simple.dart';

class AssociationMembershipNotifier extends Notifier<AssociationMembership> {
  @override
  AssociationMembership build() {
    return AssociationMembership.empty();
  }

  void setAssociationMembership(AssociationMembership associationMembership) {
    state = associationMembership;
  }
}

final associationMembershipProvider =
    NotifierProvider<AssociationMembershipNotifier, AssociationMembership>(
      () => AssociationMembershipNotifier(),
    );
