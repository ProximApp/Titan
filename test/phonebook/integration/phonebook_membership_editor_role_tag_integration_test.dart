import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_member_list_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/providers/membership_provider.dart';
import 'package:titan/phonebook/providers/roles_tags_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The membership editor's role-tag toggles, on the PRESIDENT side: not a
/// phonebook admin, so the first tag's role is locked to the mandate
/// holder (the `() {}` no-op arm) while the second tag toggles and
/// rewrites the apparent name — the non-admin first-tag no-op the
/// admin-path files can never take.
///
/// Own file for convention 10: this test deep-links the DETAIL branch
/// (/phonebook/association_detail/edit_association_members/add_edit_member)
/// while phonebook_membership_editor_integration_test.dart deep-links the
/// ADMIN branch — a second deferred journey in one process wedges the
/// router (route added, page never mounts; solo it passes). Being this
/// file's FIRST navigation, the journey is the isolate's genuine first.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  testWidgets('the role-tag toggles select, rename and skip the first tag', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'u-1'),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(() => scaffold.repository.phonebookGroupementsGet()).thenAnswer(
      (_) async => chopperListResponse([groupement('grp-1', 'Clubs')]),
    );
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).thenAnswer(
      (_) async => chopperListResponse([
        member('u-1', 'Bolt', 'Ada', 'Lovelace', roleTags: 'President'),
      ]),
    );
    when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
      (_) async =>
          chopperResponse(RoleTagsReturn(tags: ['President', 'Treasurer'])),
    );
    stubAssociationAndProfilePictures(scaffold);

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(membershipProvider.notifier)
        .setMembership(
          MembershipComplete.empty().copyWith(associationId: 'a-1'),
        );
    // The deep link crosses AdminMiddleware(isAssociationPresidentProvider)
    // BEFORE the page would have loaded anything: pre-seed the two
    // repository-backed providers it reads, or the gate bounces on loading.
    await container.read(rolesTagsProvider.notifier).loadRolesTags();
    await container
        .read(associationMemberListProvider.notifier)
        .loadMembers('a-1', 2026);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.associationDetail}'
          '${PhonebookRouter.editAssociationMembers}'
          '${PhonebookRouter.addEditMember}',
      pumpAndSettle: false,
    );
    await settle(tester);
    // Diagnostic: the editor itself must have mounted past the gates.
    expect(find.text('Search a user'), findsOneWidget);

    TextFormField field() =>
        tester.widget<TextFormField>(find.byType(TextFormField).first);

    // The first tag is a no-op for a non-admin: the name stays empty.
    await tester.tap(find.text('President'));
    await settle(tester, frames: 4);
    expect(field().controller!.text, '');

    // The second tag selects and, because the apparent name still mirrors
    // the (empty) tag list, rewrites the field to the tag itself.
    await tester.tap(find.text('Treasurer'));
    await settle(tester, frames: 4);
    expect(field().controller!.text, 'Treasurer');
  });
}
