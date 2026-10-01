import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import 'app_scaffold.dart';

/// A minimal but realistic association: grouped, described, current mandate.
AssociationComplete association(
  String id,
  String name, {
  String groupementId = 'grp-1',
  String description = 'We build robots',
  int mandateYear = 2026,
}) => AssociationComplete.empty().copyWith(
  id: id,
  name: name,
  groupementId: groupementId,
  mandateYear: mandateYear,
  description: description,
);

AssociationGroupement groupement(String id, String name) =>
    AssociationGroupement.empty().copyWith(id: id, name: name);

MemberComplete member(
  String id,
  String nickname,
  String firstname,
  String lastname, {
  String roleName = 'President',
  String associationId = 'a-1',
  int mandateYear = 2026,
}) => MemberComplete.empty().copyWith(
  id: id,
  nickname: nickname,
  firstname: firstname,
  name: lastname,
  email: '$id@myem.fr',
  memberships: [
    MembershipComplete.empty().copyWith(
      userId: id,
      associationId: associationId,
      mandateYear: mandateYear,
      roleName: roleName,
      memberOrder: 0,
      id: 'm-$id',
    ),
  ],
);

const phonebookAdminGroupId = 'd3f91313-d7e5-49c6-b01f-c19932a7e09b';

chopper.Response<List<int>> picture404() => chopper.Response<List<int>>(
  http.Response('{"detail": "File does not exist"}', 404),
  [],
  error: 'File does not exist',
);

/// Association and profile pictures auto-load everywhere; a 404 reads as
/// "no bytes" and falls back to the placeholder asset (never valid image
/// bytes — the codec would crash, same lesson as the ph covers).
void stubPhonebookPictures(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.phonebookAssociationsAssociationIdPictureGet(
      associationId: any(named: 'associationId'),
    ),
  ).thenAnswer((_) async => picture404());
  scaffold.stubProfilePicture();
}

/// Standard shell-file preamble — delegates to the scaffold helper.
void phonebookSetUp(IntegrationScaffold scaffold) {
  scaffold.shellSetUp();
}
