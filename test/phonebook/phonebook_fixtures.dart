import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../generated/openapi_mock_factories.dart';
import '../shared/app_scaffold.dart';
import '../shared/repository_stubs.dart';

/// The phonebook admin gate group.
const phonebookAdminGroupId = 'd3f91313-d7e5-49c6-b01f-c19932a7e09b';

/// A minimal but realistic association: grouped, described, current mandate.
AssociationComplete association(
  String id,
  String name, {
  String groupementId = 'grp-1',
  String description = 'We build robots',
  int mandateYear = 2026,
}) => MockAssociationComplete.any.copyWith(
  id: id,
  name: name,
  groupementId: groupementId,
  mandateYear: mandateYear,
  description: description,
);

AssociationGroupement groupement(String id, [String name = '']) =>
    MockAssociationGroupement.any.copyWith(id: id, name: name);

MembershipComplete membershipFixture({
  String id = 'm-1',
  String userId = 'u-1',
  String associationId = 'a-1',
  int mandateYear = 2026,
  String roleName = 'President',
  String? roleTags,
  int memberOrder = 0,
}) => MockMembershipComplete.any.copyWith(
  id: id,
  userId: userId,
  associationId: associationId,
  mandateYear: mandateYear,
  roleName: roleName,
  roleTags: roleTags,
  memberOrder: memberOrder,
);

MemberComplete memberWithMemberships(
  String id,
  List<MembershipComplete> memberships,
) => MockMemberComplete.any.copyWith(id: id, memberships: memberships);

MemberComplete member(
  String id,
  String nickname,
  String firstname,
  String lastname, {
  String roleName = 'President',
  String associationId = 'a-1',
  int mandateYear = 2026,
  String? roleTags,
}) => MockMemberComplete.any.copyWith(
  id: id,
  nickname: nickname,
  firstname: firstname,
  name: lastname,
  email: '$id@myem.fr',
  memberships: [
    MockMembershipComplete.any.copyWith(
      userId: id,
      associationId: associationId,
      mandateYear: mandateYear,
      roleName: roleName,
      roleTags: roleTags,
      memberOrder: 0,
      id: 'm-$id',
    ),
  ],
);

/// Stubs shared association/profile image fallback responses.
void stubAssociationAndProfilePictures(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.phonebookAssociationsAssociationIdPictureGet(
      associationId: any(named: 'associationId'),
    ),
  ).thenAnswer((_) async => fileNotFound());
  stubProfilePictureFor(scaffold.repository);
}
