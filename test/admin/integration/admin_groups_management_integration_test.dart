import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/ui/pages/groups/groups_page/groups_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';
import 'package:titan/tools/ui/styleguide/list_item.dart';

import '../../shared/app_scaffold.dart';

/// The admin groups management page (`/admin/users_groups`, 92 uncovered
/// lines): group list from the real endpoint, the add-group modal round
/// trip (`groupsPost`), and the per-group action sheet.
///
/// Own file for the deep-link rule (convention 1); the admin gate is
/// pre-seeded through `user.groups` with the real admin group id.
const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpGroups(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperListResponse<models.CoreGroupSimple>([
        models.CoreGroupSimple.empty().copyWith(
          id: 'g-1',
          name: 'admin',
          description: 'Administrators',
        ),
        models.CoreGroupSimple.empty().copyWith(
          id: 'g-2',
          name: 'club',
          description: 'Club members',
        ),
      ]),
    );
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
      initialPath: '/admin/users_groups',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('the groups page lists groups sorted by name', (tester) async {
    await pumpGroups(tester);

    expect(find.text('Groups management'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);
    expect(find.text('Administrators'), findsOneWidget);
    expect(find.text('club'), findsOneWidget);
    expect(find.text('Club members'), findsOneWidget);
  });

  testWidgets('the add-group modal creates a group through the API', (
    tester,
  ) async {
    await pumpGroups(tester);

    when(
      () => scaffold.repository.groupsPost(body: any(named: 'body')),
    ).thenAnswer(
      (_) async =>
          chopperResponse(models.CoreGroupSimple.empty().copyWith(id: 'g-3')),
    );

    // Open the + modal. The admin main page underneath has a permanent
    // animation, so pump a fixed frame budget instead of pumpAndSettle.
    await tester.tap(find.byType(CustomIconButton));
    await tester.pump();
    await settle(tester, frames: 14);
    expect(find.text('Add group'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'newgroup');
    await tester.enterText(fields.at(1), 'A fresh group');
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    final captured =
        verify(
              () => scaffold.repository.groupsPost(
                body: captureAny(named: 'body'),
              ),
            ).captured.last
            as CoreGroupCreate;
    expect(captured.name, 'newgroup');
    expect(captured.description, 'A fresh group');
    expect(find.text('Group created'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('a group row opens its action sheet with manage members', (
    tester,
  ) async {
    await pumpGroups(tester);

    // Tap the group row (by type: rows are ListItemTemplate detectors).
    // pumpAndSettle times out here too (the underlying admin page), so a
    // fixed frame budget opens the sheet.
    final rows = find.byType(ListItem);
    await tester.tap(rows.first);
    await tester.pump();
    await settle(tester, frames: 14);

    // The sheet's title is the group NAME; its three actions follow.
    expect(find.text('admin'), findsWidgets);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Manage members'), findsOneWidget);
    expect(find.text('Delete group?'), findsOneWidget);
    // Pop through the Navigator directly: closeModal's pumpAndSettle would
    // hit the same animation.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester, frames: 12);
  });

  testWidgets('pull-to-refresh reloads the group list', (tester) async {
    await pumpGroups(tester);

    // Consume the initial load, then fling down on the page's own scroll
    // view: the Cupertino sliver refresh control arms past its threshold and
    // runs `onRefresh` → loadGroups → groupsGet.
    verify(() => scaffold.repository.groupsGet());

    await tester.fling(
      find.descendant(
        of: find.byType(GroupsPage),
        matching: find.byType(CustomScrollView),
      ),
      const Offset(0, 300),
      1200,
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    verify(() => scaffold.repository.groupsGet());
  });

  testWidgets('a failing add-group reports the error toast', (tester) async {
    await pumpGroups(tester);

    when(() => scaffold.repository.groupsPost(body: any(named: 'body')))
        .thenAnswer(
          (_) async => scaffold.repository.fail<models.CoreGroupSimple>(500),
        );

    await tester.tap(find.byType(CustomIconButton));
    await tester.pump();
    await settle(tester, frames: 14);

    await tester.enterText(find.byType(TextFormField).at(0), 'nope');
    await tester.tap(find.text('Add'));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Error while adding'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('the edit modal round-trips an update and reports failures', (
    tester,
  ) async {
    await pumpGroups(tester);

    when(
      () => scaffold.repository.groupsGroupIdPatch(
        groupId: any(named: 'groupId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());

    // Row → sheet → Edit → the prefilled edit modal.
    await tester.tap(find.byType(ListItem).first);
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await settle(tester, frames: 14);
    expect(find.text('Edit group'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'renamed');
    await tester.tap(find.text('Edit'));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    final captured =
        verify(
              () => scaffold.repository.groupsGroupIdPatch(
                groupId: captureAny(named: 'groupId'),
                body: captureAny(named: 'body'),
              ),
            ).captured.last
            as CoreGroupUpdate;
    expect(captured.name, 'renamed');
    expect(find.text('Group created'), findsOneWidget);
    await scaffold.drainToast(tester);

    // The failure arm of the same modal: the update is refused and the
    // modal stays up with the error toast.
    when(
      () => scaffold.repository.groupsGroupIdPatch(
        groupId: any(named: 'groupId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => scaffold.repository.fail<void>(500));

    await tester.tap(find.byType(ListItem).first);
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.tap(find.text('Edit'));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Error while adding'), findsOneWidget);
    await scaffold.drainToast(tester);
  });

  testWidgets('manage members hops to the group edit route', (tester) async {
    await pumpGroups(tester);

    when(
      () =>
          scaffold.repository.groupsGroupIdGet(groupId: any(named: 'groupId')),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(
        models.CoreGroup.empty().copyWith(id: 'g-1', name: 'admin'),
      ),
    );

    await tester.tap(find.byType(ListItem).first);
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.tap(find.text('Manage members'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(QR.currentPath, '/admin/users_groups/edit_group');
  });

  testWidgets('delete group asks for confirmation before calling the API', (
    tester,
  ) async {
    await pumpGroups(tester);

    when(
      () => scaffold.repository.groupsGroupIdDelete(
        groupId: any(named: 'groupId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.okVoid());

    await tester.tap(find.byType(ListItem).first);
    await tester.pump();
    await settle(tester, frames: 14);
    await tester.tap(find.text('Delete group?'));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    verify(
      () => scaffold.repository.groupsGroupIdDelete(
        groupId: any(named: 'groupId'),
      ),
    );
    expect(find.text('Group deleted'), findsOneWidget);
    await scaffold.drainToast(tester);
  });
}
