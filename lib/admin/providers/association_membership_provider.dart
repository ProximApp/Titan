import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class AssociationMembershipNotifier extends Notifier<MembershipSimple> {
  @override
  MembershipSimple build() {
    return EmptyModels.empty<MembershipSimple>();
  }

  void setAssociationMembership(MembershipSimple associationMembership) {
    state = associationMembership;
  }
}

final associationMembershipProvider =
    NotifierProvider<AssociationMembershipNotifier, MembershipSimple>(
      () => AssociationMembershipNotifier(),
    );
