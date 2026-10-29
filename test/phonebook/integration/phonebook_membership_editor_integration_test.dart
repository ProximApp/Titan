import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/providers/complete_member_provider.dart';
import 'package:titan/phonebook/providers/membership_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart';

/// The membership editor's submit paths no other file drives (the member
/// flows file covers the two success round-trips only): the empty-member
/// and empty-role-name guards, the duplicate-membership guard, and the
/// failing POST/PATCH toasts. Deep links only: every success path calls
/// QR.back.
///
/// The role-tag toggles — the non-admin first-tag no-op, taken on the
/// PRESIDENT side — live in
/// phonebook_membership_editor_role_tag_integration_test.dart: their
/// detail-branch deep link is a SECOND navigation journey for this file
/// and would wedge the router in one process (convention 10).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    shellTestSetUp(scaffold);
  });

  void stubEditor(IntegrationScaffold scaffold) {
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
    ).thenAnswer((_) async => chopperListResponse(<MemberComplete>[]));
    when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
      (_) async => chopperResponse(RoleTagsReturn(tags: ['President'])),
    );
    stubAssociationAndProfilePictures(scaffold);
  }

  ProviderContainer adminContainer() => scaffold.makeContainer(
    user: CoreUser.empty().copyWith(
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: phonebookAdminGroupId,
          name: 'admin_phonebook',
        ),
      ],
    ),
  );

  Future<void> pumpEditor(WidgetTester tester, ProviderContainer container) =>
      scaffold
          .pumpApp(
            tester,
            container,
            initialPath:
                '${PhonebookRouter.root}${PhonebookRouter.admin}'
                '${PhonebookRouter.editAssociationMembers}'
                '${PhonebookRouter.addEditMember}',
            pumpAndSettle: false,
          )
          .then((_) => settle(tester));

  testWidgets('the submit guards toast before calling anything', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubEditor(scaffold);
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(membershipProvider.notifier)
        .setMembership(
          MembershipComplete.empty().copyWith(associationId: 'a-1'),
        );

    await pumpEditor(tester, container);
    expect(find.text('Add a member'), findsOneWidget);

    // No member selected yet.
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 4);
    expect(find.text('No member selected'), findsOneWidget);
    await scaffold.drainToast(tester);

    // Member selected but the public role name is empty.
    container
        .read(completeMemberProvider.notifier)
        .setCompleteMember(
          member('u-9', 'Bolt', 'Ada', 'Lovelace').copyWith(memberships: []),
        );
    await settle(tester, frames: 4);
    expect(find.textContaining('Bolt'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 4);
    expect(find.text('Please enter a role name'), findsOneWidget);
    await scaffold.drainToast(tester);
    verifyNever(
      () => scaffold.repository.phonebookAssociationsMembershipsPost(
        body: any(named: 'body'),
      ),
    );
  });

  testWidgets('a member already in the current term is refused', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubEditor(scaffold);
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(membershipProvider.notifier)
        .setMembership(
          MembershipComplete.empty().copyWith(associationId: 'a-1'),
        );
    // The default fixture membership sits on a-1 / 2026 — the current term.
    container
        .read(completeMemberProvider.notifier)
        .setCompleteMember(member('u-9', 'Bolt', 'Ada', 'Lovelace'));

    await pumpEditor(tester, container);

    await tester.enterText(find.byType(TextField).first, 'Treasurer');
    await scaffold.unfocus(tester);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 6);

    expect(
      find.text('This member is already in the current term'),
      findsOneWidget,
    );
    await scaffold.drainToast(tester);
    verifyNever(
      () => scaffold.repository.phonebookAssociationsMembershipsPost(
        body: any(named: 'body'),
      ),
    );
  });

  testWidgets('a refused membership POST toasts the add error', (tester) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubEditor(scaffold);
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    container
        .read(membershipProvider.notifier)
        .setMembership(
          MembershipComplete.empty().copyWith(associationId: 'a-1'),
        );
    container
        .read(completeMemberProvider.notifier)
        .setCompleteMember(
          member('u-9', 'Bolt', 'Ada', 'Lovelace').copyWith(memberships: []),
        );
    when(
      () => scaffold.repository.phonebookAssociationsMembershipsPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<MembershipComplete>(
        http.Response('{"detail": "nope"}', 500),
        null,
        error: 'nope',
      ),
    );

    await pumpEditor(tester, container);

    await tester.enterText(find.byType(TextField).first, 'Treasurer');
    await scaffold.unfocus(tester);
    await tester.tap(find.text('Add'));
    await settle(tester, frames: 6);

    expect(find.text('Error adding'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a refused membership PATCH toasts the update error', (
    tester,
  ) async {
    final container = adminContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubEditor(scaffold);
    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));
    // Edit mode: the membership carries an id, and the member owns a
    // matching membership (updateMember writes through it by indexWhere).
    final edited = member('u-9', 'Bolt', 'Ada', 'Lovelace').copyWith(
      memberships: [
        MembershipComplete.empty().copyWith(
          id: 'm-x',
          userId: 'u-9',
          associationId: 'a-1',
          mandateYear: 2026,
          roleName: 'President',
          memberOrder: 0,
        ),
      ],
    );
    container.read(completeMemberProvider.notifier).setCompleteMember(edited);
    container
        .read(membershipProvider.notifier)
        .setMembership(edited.memberships.first);
    when(
      () =>
          scaffold.repository.phonebookAssociationsMembershipsMembershipIdPatch(
            membershipId: 'm-x',
            body: any(named: 'body'),
          ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(
        http.Response('{"detail": "nope"}', 500),
        null,
        error: 'nope',
      ),
    );

    await pumpEditor(tester, container);
    expect(find.textContaining("Modify Bolt's role"), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 6);

    expect(find.text('Error during update'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
