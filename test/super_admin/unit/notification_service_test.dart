import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/router.dart';
import 'package:titan/super_admin/notification_service.dart';
import 'package:titan/super_admin/router.dart';
import 'package:titan/user/providers/user_provider.dart';

/// `adminProviders` is the push-notification routing table: it maps a message
/// action to the screen that owns the data it changes, plus the providers that
/// screen has to reload. Nothing imports it directly except the service
/// provider list, so the whole map was a dark line — a typo in a path or a
/// missing invalidation would only surface when a real push arrived.
void main() {
  test('every action points at a real screen and the providers to reload', () {
    expect(adminProviders.keys, containsAll(['user', 'userGroups', 'groups']));

    // "user" is the signed-in reader's own profile: the app root shows it.
    expect(adminProviders['user']!.item1, AppRouter.root);
    expect(adminProviders['user']!.item2, [asyncUserProvider]);

    // A group change touches the reader's groups list AND their own record,
    // which carries the group ids.
    expect(adminProviders['userGroups']!.item1, AppRouter.root);
    expect(adminProviders['userGroups']!.item2, [
      allGroupListProvider,
      asyncUserProvider,
    ]);

    // The admin group list lives on the super admin screen, not the root.
    expect(adminProviders['groups']!.item1, SuperAdminRouter.root);
    expect(adminProviders['groups']!.item2, [allGroupListProvider]);
  });
}
