import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/providers/group_id_provider.dart';
import 'package:titan/admin/ui/components/user_ui.dart';
import 'package:titan/admin/ui/pages/groups/edit_group_page/edit_group_page.dart';
import 'package:titan/admin/ui/pages/groups/edit_group_page/search_user.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';

import '../../shared/app_scaffold.dart';

/// Deep link to `/admin/users_groups/edit_group` — the last admin route with
/// NO test at all (`EditGroupPage` sat at 0/19, under a green
/// `/admin/users_groups` tree). The parent chain (admin main page → groups
/// list) mounts underneath, `groupIdProvider` is seeded the way
/// `groups_page`'s "Manage members" button sets it, and
/// `SingleAutoLoaderChild` pulls the group through `groupsGroupIdGet` before
/// `SearchUser` renders.
///
/// The page's `Refresher.onRefresh` closure is driven the way the
/// association page's is (`admin_association_refresh_arms`): the widget is
/// read off the tree and its callback awaited. A gesture cannot arm the
/// Cupertino control (the sliver accepts the drag and springs back), but the
/// closure the platform control would call is the page's own public wiring,
/// so awaiting it is the reload the user gets.
///
/// `SearchUser`'s trailing `?? []` is the group MEMBER list falling back when
/// the group carries no members — not the async value (the outer
/// `SingleAutoLoaderChild` guarantees data). A `CoreGroup` without a `members`
/// key is what the backend sends for a group nobody joined yet, so the last
/// test loads one and asserts the page renders with no member rows.
const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
    // The parent GroupsPage's list (re-stubbed over the scaffold's []).
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => scaffold.repository.ok([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE'),
      ]),
    );
    // The group the edit page auto-loads for groupIdProvider's id.
    when(
      () =>
          scaffold.repository.groupsGroupIdGet(groupId: any(named: 'groupId')),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(
        CoreGroup.empty().copyWith(
          id: 'g-1',
          name: 'BDE',
          members: [
            CoreUserSimple.empty().copyWith(
              id: 'u1',
              firstname: 'Alice',
              name: 'Durand',
            ),
            CoreUserSimple.empty().copyWith(
              id: 'u2',
              firstname: 'Bob',
              name: 'Martin',
            ),
          ],
        ),
      ),
    );
  });

  Future<void> pumpEditGroup(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(
        id: 'me',
        groups: [
          CoreGroupSimple.empty().copyWith(id: adminGroupId, name: 'admin'),
        ],
      ),
    );
    container.read(groupIdProvider.notifier).setId('g-1');
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/admin/users_groups/edit_group',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  testWidgets('the deep link loads the group and lists its members', (
    tester,
  ) async {
    await pumpEditGroup(tester);

    expect(QR.currentPath, '/admin/users_groups/edit_group');

    // This file's FIRST navigation loads three deferred libraries for real
    // (admin main page → groups page → edit page), and a fixed frame budget
    // can outrun that cold start — poll frames until the auto-loaded group
    // is on screen, bounded so a genuine break still fails instead of
    // hanging. (The parent GroupsPage's own list is its pages' business,
    // covered by admin_groups_management; this route owns the group body.)
    var polls = 0;
    while (polls < 120 && find.text('Alice Durand').evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 60));
      polls++;
    }

    // Rendered through SingleAutoLoaderChild's data arm — if the auto-load
    // never resolves, none of this is on screen.
    expect(find.text('Alice Durand'), findsOneWidget);
    expect(find.text('Bob Martin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the add-member sheet opens from the real route', (tester) async {
    await pumpEditGroup(tester);

    // Scoped to SearchUser's own plus: the parent GroupsPage has one too.
    await tester.tap(
      find.descendant(
        of: find.byType(SearchUser),
        matching: find.byType(CustomIconButton),
      ),
    );
    // WaitingButton: its onTap awaits the sheet closing, so the Loader spins
    // while the sheet is open — fixed frames, never pumpAndSettle.
    await tester.pump();
    await settle(tester, frames: 14);

    expect(find.text('Add member'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the add-member sheet resets its search when cleared', (
    tester,
  ) async {
    // The sheet's own bar: a query filters through usersSearchGet with the
    // group excluded, and emptying the field clears the list instead of
    // leaving the previous results on screen.
    when(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query'),
        excludedGroups: any(named: 'excludedGroups'),
      ),
    ).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <CoreUserSimple>[
            CoreUserSimple.empty().copyWith(id: 'u-9', name: 'Alice Elsewhere'),
          ]),
    );

    await pumpEditGroup(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(SearchUser),
        matching: find.byType(CustomIconButton),
      ),
    );
    await tester.pump();
    await settle(tester, frames: 14);
    expect(find.text('Add member'), findsOneWidget);

    final sheetField = find
        .descendant(
          of: find.byType(BottomModalTemplate),
          matching: find.byType(TextField),
        )
        .last;
    await tester.enterText(sheetField, 'Ali');
    await tester.pump();
    await settle(tester, frames: 10);
    // The result row pads its label, so match on the content.
    expect(find.textContaining('Alice Elsewhere'), findsOneWidget);

    await tester.enterText(sheetField, '');
    await tester.pump();
    await settle(tester, frames: 10);
    expect(find.textContaining('Alice Elsewhere'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the refresher reloads the group it is showing', (tester) async {
    var groupRequests = 0;
    when(
      () =>
          scaffold.repository.groupsGroupIdGet(groupId: any(named: 'groupId')),
    ).thenAnswer((_) async {
      groupRequests++;
      return scaffold.repository.ok(
        CoreGroup.empty().copyWith(
          id: 'g-1',
          name: 'BDE',
          members: [
            CoreUserSimple.empty().copyWith(
              id: 'u1',
              firstname: 'Alice',
              name: 'Durand',
            ),
          ],
        ),
      );
    });

    await pumpEditGroup(tester);
    expect(find.text('Alice Durand'), findsOneWidget);
    expect(
      groupRequests,
      1,
      reason: 'the auto-load is the only request so far',
    );

    // The callback the platform refresh control is handed, awaited directly:
    // a drag only springs the sliver back in this harness.
    final refresher = tester.widget<Refresher>(
      find.descendant(
        of: find.byType(EditGroupPage),
        matching: find.byType(Refresher),
      ),
    );
    await tester.runAsync(() async {
      await refresher.onRefresh();
    });
    await settle(tester, frames: 24);

    // One more group GET, and the members it answers with stay on screen.
    expect(groupRequests, 2);
    expect(find.text('Alice Durand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a group with no members renders without member rows', (
    tester,
  ) async {
    // `CoreGroup.empty()` carries no `members` key at all — what the backend
    // sends for a group nobody has joined. The page has to fall back to an
    // empty list instead of dropping the whole members section.
    when(
      () =>
          scaffold.repository.groupsGroupIdGet(groupId: any(named: 'groupId')),
    ).thenAnswer(
      (_) async => scaffold.repository.ok(
        CoreGroup.empty().copyWith(id: 'g-1', name: 'BDE'),
      ),
    );

    await pumpEditGroup(tester);
    var polls = 0;
    while (polls < 120 && find.byType(SearchUser).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 60));
      polls++;
    }

    expect(find.byType(SearchUser), findsOneWidget);
    // No member rows at all, and the page still builds around them.
    expect(find.byType(UserUi), findsNothing);
    expect(find.text('Alice Durand'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
