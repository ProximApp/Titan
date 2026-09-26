import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/providers/association_membership_provider.dart';
import 'package:titan/admin/providers/user_association_membership_provider.dart';
import 'package:titan/admin/ui/pages/membership/add_edit_user_membership_page/user_search_modal.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

/// The admin add-edit user membership page
/// (`/admin/association_memberships/detail_association_membership
/// /add_edit_member`, 96 uncovered lines), reached in create mode.
///
/// The page keeps its target in userAssociationMembershipProvider; a
/// create needs a picked user (via the search modal) plus start/end dates,
/// then POSTs through associationMembershipMembersProvider.addMember.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpAddMember(
    WidgetTester tester, {
    ProviderContainer? container,
  }) async {
    scaffold.setWideSurface(tester);
    scaffold.stubAdminMainPage();
    final appContainer =
        container ??
        scaffold.makeContainer(
          user: models.CoreUser.empty().copyWith(
            id: 'me',
            groups: [
              models.CoreGroupSimple.empty().copyWith(
                id: adminGroupId,
                name: 'admin',
              ),
            ],
          ),
        );
    await scaffold.pumpApp(
      tester,
      appContainer,
      initialPath: '/admin/association_memberships/detail_association_membership/add_edit_member',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    return appContainer;
  }

  testWidgets('the create form renders the user row and date entries', (
    tester,
  ) async {
    final container = await pumpAddMember(tester);

    expect(find.text('Add member'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('End date'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('saving without a user shows the empty-user toast', (
    tester,
  ) async {
    final container = await pumpAddMember(tester);

    // Fill valid dates but no user: the user check fires first.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '01/01/2026');
    await tester.enterText(fields.at(1), '31/12/2026');
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Add'));
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Empty user'), findsOneWidget);
    verifyNever(
      () => scaffold.repository.membershipsUsersUserIdPost(
        userId: any(named: 'userId'),
        body: any(named: 'body'),
      ),
    );
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('user picker searches and assigns a member', (tester) async {
    final container = scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(
        id: 'me',
        groups: [
          models.CoreGroupSimple.empty().copyWith(
            id: adminGroupId,
            name: 'admin',
          ),
        ],
      ),
    );
    var searchCalls = 0;
    when(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query'),
        includedAccountTypes: any(named: 'includedAccountTypes'),
        excludedAccountTypes: any(named: 'excludedAccountTypes'),
        includedGroups: any(named: 'includedGroups'),
        excludedGroups: any(named: 'excludedGroups'),
      ),
    ).thenAnswer((_) async {
      searchCalls++;
      return chopperListResponse([
        models.CoreUserSimple.empty().copyWith(
          id: 'u-9',
          firstname: 'Ada',
          name: 'Lovelace',
        ),
      ]);
    });
    await pumpAddMember(tester, container: container);

    await tester.tap(find.text('User'));
    await settle(tester, frames: 8);
    final modal = find.byType(UserSearchModal);
    expect(modal, findsOneWidget);
    final query = find.descendant(of: modal, matching: find.byType(TextField));
    expect(query, findsOneWidget);
    await tester.enterText(query, 'Ada');
    await settle(tester, frames: 16);
    expect(searchCalls, greaterThanOrEqualTo(1));
    expect(find.text('Ada Lovelace'), findsOneWidget);
    final addUser = find.descendant(
      of: modal,
      matching: find.byWidgetPredicate(
        (widget) => widget is HeroIcon && widget.icon == HeroIcons.plus,
      ),
    );
    expect(addUser, findsOneWidget);
    await tester.tap(addUser);
    await settle(tester, frames: 12);

    expect(find.byType(UserSearchModal), findsNothing);
    expect(container.read(userAssociationMembershipProvider).user.id, 'u-9');
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
    container.dispose();
  });

  testWidgets('a picked user and dates add the member through the API', (
    tester,
  ) async {
    final container = await pumpAddMember(tester);

    // The create flow needs an association membership context: set it the
    // way the parent detail page does before forwarding here. The
    // ProviderContainer comes from the ProviderScope above the app.
    final member = models.UserMembershipComplete.empty().copyWith(
      associationMembershipId: 'am-1',
      user: models.CoreUserSimple.empty().copyWith(id: 'u-9'),
    );
    container
        .read(userAssociationMembershipProvider.notifier)
        .setUserAssociationMembership(member);

    // The pop-back target is the membership's detail page: seed the parent
    // membership the way the association membership page does before
    // forwarding here, with a manager group that exists in the group list.
    container
        .read(associationMembershipProvider.notifier)
        .setAssociationMembership(
          models.MembershipSimple(
            name: 'Mandate 2026',
            managerGroupId: 'g-1',
            id: 'am-1',
          ),
        );

    // On success the page pops back to the detail page underneath. Its
    // editor looks up the membership's manager group in the group list
    // with a bare firstWhere, so the list must contain managerGroupId
    // when that mount happens. The shell default stubs groupsGet to an
    // empty list and the admin main page underneath has already loaded
    // it during the initial pumps — re-stub and re-run the loader.
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse([
        models.CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'Admins'),
      ]),
    );
    await container.read(allGroupListProvider.notifier).loadGroups();
    await tester.pump();

    when(
      () => scaffold.repository.membershipsUsersUserIdPost(
        userId: 'u-9',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => chopperResponse(models.UserMembershipComplete.empty()),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '01/01/2026');
    await tester.enterText(fields.at(1), '31/12/2026');
    await scaffold.unfocus(tester);
    await scaffold.ensureOnScreen(tester, find.text('Add'));
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Member added'), findsOneWidget);
    await scaffold.drainToast(tester);
    await scaffold.unmountApp(tester);
    container.dispose();
  });
}
