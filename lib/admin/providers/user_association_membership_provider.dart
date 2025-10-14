import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class UserAssociationMembershipNotifier
    extends Notifier<UserMembershipComplete> {
  @override
  UserMembershipComplete build() {
    return EmptyModels.empty<UserMembershipComplete>();
  }

  void setUserAssociationMembership(
    UserMembershipComplete userUserAssociationMembership,
  ) {
    state = userUserAssociationMembership;
  }
}

final userAssociationMembershipProvider =
    NotifierProvider<UserAssociationMembershipNotifier, UserMembershipComplete>(
      UserAssociationMembershipNotifier.new,
    );
