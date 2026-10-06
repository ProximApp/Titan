import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/providers/association_membership_provider.dart';
import 'package:titan/admin/providers/user_association_membership_provider.dart';
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

  Future<void> pumpAddMember(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    scaffold.stubAdminMainPage();
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
    await scaffold.pumpApp(
      tester,
      container,
      initialPath:
          '/admin/association_memberships/detail_association_membership/add_edit_member',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the create form renders the user row and date entries', (
    tester,
  ) async {
    await pumpAddMember(tester);

    expect(find.text('Add member'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('End date'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('saving without a user shows the empty-user toast', (
    tester,
  ) async {
    await pumpAddMember(tester);

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
  });

  testWidgets('a picked user and dates add the member through the API', (
    tester,
  ) async {
    await pumpAddMember(tester);

    // The create flow needs an association membership context: set it the
    // way the parent detail page does before forwarding here. The
    // ProviderContainer comes from the ProviderScope above the app.
    final container = ProviderScope.containerOf(
      tester.element(find.text('Add member').first),
    );
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
  });
}
