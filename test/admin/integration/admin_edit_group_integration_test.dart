import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/providers/group_id_provider.dart';
import 'package:titan/admin/ui/pages/groups/edit_group_page/search_user.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';

import '../../shared/app_scaffold.dart';

/// Deep link to `/admin/users_groups/edit_group` — the last admin route with
/// NO test at all (`EditGroupPage` sat at 0/19, under a green
/// `/admin/users_groups` tree). The parent chain (admin main page → groups
/// list) mounts underneath, `groupIdProvider` is seeded the way
/// `groups_page`'s "Manage members" button sets it, and
/// `SingleAutoLoaderChild` pulls the group through `groupsGroupIdGet` before
/// `SearchUser` renders.
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
}
