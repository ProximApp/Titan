import 'package:titan/generated/openapi.models.swagger.dart';

extension MembershipSimpleDisplay on MembershipSimple {
  bool get isEmptyMembership => id.isEmpty;

  String displayName(String noMembershipLabel) {
    if (isEmptyMembership) {
      return noMembershipLabel;
    }
    return name;
  }
}
