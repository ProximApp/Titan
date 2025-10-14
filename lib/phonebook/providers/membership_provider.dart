import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

final membershipProvider =
    NotifierProvider<MembershipProvider, MembershipComplete>(
      () => MembershipProvider(),
    );

class MembershipProvider extends Notifier<MembershipComplete> {
  @override
  MembershipComplete build() {
    return EmptyModels.empty<MembershipComplete>();
  }

  void setMembership(MembershipComplete i) {
    state = i;
  }
}
