import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';

/// The full add-member flow on the members admin page, driven through the
/// real UI: page → "Add a member" list item → editor page → user-search
/// bottom sheet → search → pick a result → role name → submit. The modal
/// lifecycle goes through the scaffold's openModal/closeModal drivers.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the user-search modal round-trip selects a member', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: phonebookAdminGroupId,
            name: 'admin_phonebook',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubPhonebookPictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).thenAnswer((_) async => chopperListResponse(<MemberComplete>[]));
    // The user-search modal queries the real search endpoint.
    when(() => scaffold.repository.usersSearchGet(query: 'ada')).thenAnswer(
      (_) async => chopperListResponse([
        CoreUserSimple.empty().copyWith(
          id: 'u-9',
          firstname: 'Ada',
          name: 'Lovelace',
          nickname: null,
          accountType: enums.AccountType.student,
          schoolId: '',
        ),
      ]),
    );

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.editAssociationMembers}',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(scaffold.isModalOpen(tester), isFalse);

    // Open the membership editor page via the "Add a member" item.
    await scaffold.openModal(tester, find.text('Add a member'));

    // The editor page (not a modal) mounts: add mode with the search entry.
    expect(find.text('Add a member'), findsWidgets);
    expect(find.text('Search a user'), findsOneWidget);

    // The user-search BOTTOM SHEET opens from the editor page.
    await scaffold.openModal(tester, find.text('Search a user'));
    expect(scaffold.isModalOpen(tester), isTrue);
    expect(find.text('Search a user'), findsWidgets);

    // Type a query; the modal runs the real search endpoint.
    await tester.enterText(find.byType(TextField).last, 'ada');
    await settle(tester, frames: 8);

    // The result card carries the real CoreUserSimple data.
    expect(find.text('Ada Lovelace'), findsOneWidget);

    // Tapping it selects the member, closes the sheet, and kicks the
    // complete-member fetch.
    when(
      () => scaffold.repository.phonebookMemberUserIdGet(userId: 'u-9'),
    ).thenAnswer(
      (_) async => chopperResponse(
        // No memberships yet — the fixture builder adds one by default,
        // which would trip the real duplicate-membership guard.
        member('u-9', 'Ada', 'Ada', 'Lovelace').copyWith(memberships: []),
      ),
    );
    await scaffold.tapInModal(tester, find.text('Ada Lovelace'));

    expect(scaffold.isModalOpen(tester), isFalse);
    // The editor now shows the selected member's name instead of the search
    // entry, and the submit button is enabled.
    expect(find.textContaining('Ada Lovelace'), findsWidgets);
    expect(find.text('Add'), findsOneWidget);

    // Fill the role name and submit: the real POST fires.
    when(
      () => scaffold.repository.phonebookAssociationsMembershipsPost(
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(
        MembershipComplete.empty().copyWith(
          id: 'm-new',
          userId: 'u-9',
          associationId: 'a-1',
          mandateYear: 2026,
          roleName: 'Treasurer',
          memberOrder: 0,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'Treasurer');
    await settle(tester, frames: 4);
    await scaffold.tapInModal(tester, find.text('Add'));

    await settle(tester, frames: 8);
    // The editor pops back to the members page; the new member's card shows
    // "nickname - roleName".
    expect(find.textContaining('Ada - Treasurer'), findsOneWidget);
    // Let the success toast auto-close (2.5s timer) so no timer stays
    // pending when the test ends (see tickets_main_page shell).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('the member-edition modal opens and edits the role', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: phonebookAdminGroupId,
            name: 'admin_phonebook',
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubPhonebookPictures(scaffold);
    when(() => scaffold.repository.phonebookAssociationsGet()).thenAnswer(
      (_) async => chopperListResponse([association('a-1', 'Robot Club')]),
    );
    when(
      () => scaffold.repository
          .phonebookAssociationsAssociationIdMembersMandateYearGet(
            associationId: 'a-1',
            mandateYear: 2026,
          ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse([member('u-1', 'Bolt', 'Ada', 'Lovelace')]),
    );

    container
        .read(associationProvider.notifier)
        .setAssociation(association('a-1', 'Robot Club'));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '${PhonebookRouter.root}${PhonebookRouter.admin}${PhonebookRouter.editAssociationMembers}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // Tapping the editable member card opens the member-edition modal. The
    // card title and the modal title render the SAME "Bolt - President"
    // text, so the finder matches two widgets while the sheet is open.
    await scaffold.openModal(
      tester,
      find.textContaining('Bolt - President').first,
    );
    expect(scaffold.isModalOpen(tester), isTrue);
    // Modal title: "nickname - roleName"; body: edit + delete actions.
    expect(find.text('Bolt - President'), findsNWidgets(2));
    expect(find.text('Edit role'), findsOneWidget);
    expect(find.text('Delete role'), findsOneWidget);

    // "Edit role" closes the sheet and routes to the editor in edit mode.
    when(() => scaffold.repository.phonebookRoletagsGet()).thenAnswer(
      (_) async => chopperResponse(RoleTagsReturn(tags: ['President'])),
    );
    await scaffold.tapInModal(tester, find.text('Edit role'));
    expect(scaffold.isModalOpen(tester), isFalse);
    expect(find.text("Modify Bolt's role"), findsOneWidget);
    // The apparent-name field is prefilled from the membership.
    expect(find.text('Public role name:'), findsOneWidget);

    // Submitting the edit fires the real membership PATCH (a void response
    // endpoint — success is the isSuccessful flag alone).
    when(
      () =>
          scaffold.repository.phonebookAssociationsMembershipsMembershipIdPatch(
            membershipId: 'm-u-1',
            body: any(named: 'body'),
          ),
    ).thenAnswer(
      (_) async => chopper.Response<void>(http.Response('body', 200), null),
    );
    await scaffold.tapInModal(tester, find.text('Edit'));

    await settle(tester, frames: 10);
    // Back on the members page with the member card still rendered.
    expect(find.textContaining('Bolt - President'), findsOneWidget);
    // Drain the toast auto-close timer (see above).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
