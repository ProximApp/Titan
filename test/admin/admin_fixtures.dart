import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import 'package:titan/tools/ui/styleguide/list_item.dart';

import '../shared/app_scaffold.dart';

/// The admin module's own test doubles and builders: every admin test that
/// needs a pre-seeded group list or membership state takes them from here
/// instead of rebuilding the class (the group-list fake was copied verbatim
/// into two widget tests, the membership one into a unit and a widget test).
///
/// Fixtures shared by several files of ONE module live here; a helper only
/// one file needs stays in that file. Platform-wide stubs (pickers, route
/// mocks, url_launcher) belong in `test/shared/*_stub.dart` instead.
class GroupListFake extends GroupListNotifier {
  GroupListFake(this.groups);

  final List<CoreGroupSimple> groups;

  @override
  AsyncValue<List<CoreGroupSimple>> build() => AsyncValue.data(groups);
}

/// The membership list in its loading state: the spinner branch of the
/// detail page's members section.
class MembersNotifier extends AssociationMembershipMembersNotifier {
  @override
  AsyncValue<List<UserMembershipComplete>> build() =>
      const AsyncValue.loading();
}

/// The signed-in admin every admin integration test acts as.
const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
);

/// Opens `/admin` on a wide surface. The main page's own routes each need
/// their own test file: qlevar_router 1.12.4 only processes the first
/// mid-test navigation of an isolate, so one route is asserted per file.
Future<void> pumpAdminMain(
  WidgetTester tester,
  IntegrationScaffold scaffold,
) async {
  scaffold.shellSetUp();
  scaffold.stubAdminMainPage();
  scaffold.setWideSurface(tester);
  await scaffold.pumpApp(
    tester,
    scaffold.makeContainer(user: adminUser),
    initialPath: '/admin',
    pumpAndSettle: false,
  );
  await settle(tester, frames: 24);
}

/// Taps the main page's list item at [index] and waits for the route to move.
Future<void> tapAdminItem(
  WidgetTester tester,
  int index,
  String expectedPath,
) async {
  await tester.tap(find.byType(ListItem).at(index));
  for (var i = 0; i < 60 && QR.currentPath != expectedPath; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
