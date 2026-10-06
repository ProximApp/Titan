import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/super_admin/tools/module_roots.dart';

/// `computeUserModuleRoots` decides WHICH MODULES A USER MAY OPEN. It feeds
/// `module_list_provider.dart`, whose visible-module filter is
/// `enabledNames.contains(root) && roots.contains(m.root)`, so no root it
/// fails to produce can appear in the user's navigation.
///
/// It had no test in `test/` at all, for a reason that is not its own fault:
/// every shell hands it an EMPTY permission catalog
/// (`FakePermissionsNamesListNotifier` returns `[]` in three of four
/// containers), so `buildPermissionToModuleRootMap` returned an empty map and
/// every lookup hit its `continue` (ledger #55).
///
/// **Writing those tests turned up a production defect, which this file now
/// pins.** `buildPermissionToModuleRootMap` keys its map by the name with the
/// module prefix STRIPPED, so `booking.access` and `feed.access` both become
/// the single key `access`. But `computeUserModuleRoots` looks the map up with
/// `permissionToModule[permission.permissionName]`, the FULL name.
///
/// Which of the two shapes the backend sends is not knowable from this repo,
/// and the codebase itself hedges: `permissions.dart` resolves a permission as
/// `mappedPermissions[fullName] ?? mappedPermissions[shortName]`, accepting
/// either. Both are pinned below, and BOTH are wrong:
///
///  - FULL name (booking.access) - the lookup misses, every module is
///    dropped, and the user is offered Settings and nothing else.
///  - BARE name (access) - the lookup hits, but every module collides on the
///    one key, so they all resolve to whichever module came LAST.
///
/// Neither is a safe default, and choosing one silently would be a guess about
/// who may open what. The `KNOWN BUG` groups below therefore pin the CURRENT
/// behaviour, so that any edit to `module_roots.dart` trips them and forces
/// the question to be answered deliberately.
void main() {
  CorePermission permission(
    String name, {
    List<String> groups = const [],
    List<enums.AccountType> types = const [],
  }) =>
      CorePermission(permissionName: name, groups: groups, accountTypes: types);

  CoreUser user({
    enums.AccountType accountType = enums.AccountType.student,
    List<CoreGroupSimple> groups = const [],
  }) => CoreUser.empty().copyWith(accountType: accountType, groups: groups);

  /// A staff account: the user in every test below holds staff-scoped
  /// permissions.
  final staff = user(accountType: enums.AccountType.staff);

  group('buildPermissionToModuleRootMap', () {
    test('splits a module-prefixed name into its two halves', () {
      expect(buildPermissionToModuleRootMap(['booking.access']), {
        'access': 'booking',
      });
    });

    test('a name without a dot is skipped entirely', () {
      // `continue`, not a map entry with an empty root: an unqualified
      // permission cannot be attributed to a module.
      final map = buildPermissionToModuleRootMap(['admin', 'booking.access']);

      expect(map.containsKey('admin'), isFalse);
      expect(map, {'access': 'booking'});
    });

    test('an empty catalog produces an empty map', () {
      // The state every shell used to hand it, and the reason this function
      // was untested rather than merely unexercised.
      expect(buildPermissionToModuleRootMap(const []), isEmpty);
    });

    test('the split is at the FIRST dot, not the last', () {
      // `indexOf('.')` finds the first one, so everything after it becomes the
      // key: `a.b.access` becomes key `b.access`, not `access`. Pinned because
      // it is the difference between "one key per permission" and "one key
      // per module", and the collision below depends on which.
      expect(buildPermissionToModuleRootMap(['a.b.access']), {'b.access': 'a'});
    });

    test('KNOWN BUG: same-named permissions collide into one key', () {
      expect(
        buildPermissionToModuleRootMap([
          'booking.access',
          'feed.access',
          'amap.access',
        ]),
        {'access': 'amap'},
        reason:
            'the key is the name with the module prefix stripped, so the three '
            'access permissions overwrite one another and only the last '
            'survives. Nothing consuming this map can tell the modules apart.',
      );
    });
  });

  group('userHasPermission', () {
    test('a shared group grants it', () {
      expect(
        userHasPermission(
          user(
            groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
          ),
          permission('booking.access', groups: ['g-1']),
        ),
        isTrue,
      );
    });

    test('a matching account type grants it', () {
      expect(
        userHasPermission(
          staff,
          permission('booking.access', types: [enums.AccountType.staff]),
        ),
        isTrue,
      );
    });

    test('neither a group nor an account type match denies it', () {
      expect(
        userHasPermission(
          user(
            accountType: enums.AccountType.student,
            groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
          ),
          permission(
            'booking.access',
            groups: ['g-2'],
            types: [enums.AccountType.staff],
          ),
        ),
        isFalse,
      );
    });

    test('a group match wins over a mismatched account type', () {
      expect(
        userHasPermission(
          user(
            accountType: enums.AccountType.student,
            groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
          ),
          permission(
            'booking.access',
            groups: ['g-1'],
            types: [enums.AccountType.staff],
          ),
        ),
        isTrue,
      );
    });

    test('a user with no groups does not crash the lookup', () {
      // `(user.groups ?? [])` - `CoreUser.groups` is nullable, and the naive
      // version threw on a user who has never joined anything.
      expect(
        userHasPermission(
          CoreUser.empty(),
          permission('booking.access', groups: ['g-1']),
        ),
        isFalse,
      );
    });
  });

  group('computeUserModuleRoots', () {
    const catalog = ['booking.access', 'feed.access', 'amap.access'];

    test('an empty catalog grants nothing, however many permissions', () {
      expect(
        computeUserModuleRoots(
          user: staff,
          permissions: [
            permission('booking.access', types: [enums.AccountType.staff]),
            permission('feed.access', types: [enums.AccountType.staff]),
          ],
          permissionCatalog: const [],
        ),
        isEmpty,
      );
    });

    test('no permissions grants nothing', () {
      expect(
        computeUserModuleRoots(
          user: staff,
          permissions: const [],
          permissionCatalog: catalog,
        ),
        isEmpty,
      );
    });

    test('a permission whose name lacks "access" is ignored', () {
      expect(
        computeUserModuleRoots(
          user: staff,
          permissions: [
            permission('booking.write', types: [enums.AccountType.staff]),
          ],
          permissionCatalog: ['booking.write'],
        ),
        isEmpty,
      );
    });

    test('a permission the user does not hold grants nothing', () {
      expect(
        computeUserModuleRoots(
          user: staff,
          permissions: [
            permission(
              'booking.access',
              types: [enums.AccountType.formerStudent],
            ),
          ],
          permissionCatalog: catalog,
        ),
        isEmpty,
      );
    });

    group('KNOWN BUG: the map key and the lookup key disagree', () {
      test('a FULL permission name resolves to no module at all', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('booking.access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: catalog,
          ),
          isEmpty,
          reason:
              'the user demonstrably holds booking.access as staff and the '
              'catalog lists it, yet no module comes back: the map is keyed by '
              'access and the lookup uses booking.access. In the app this '
              'empties the visible list in module_list_provider.',
        );
      });

      test('a BARE permission name resolves to the LAST catalog module', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: ['booking.access', 'feed.access'],
          ),
          ['feed'],
          reason:
              'every module collides on the single key access, so '
              'booking.access resolves to feed, the last entry to overwrite '
              'it. A change here means the right answer is being guessed at '
              'rather than decided.',
        );
      });

      test('a single-module catalog still misses on the full name', () {
        // With one module there is nothing to collide with, so only the key
        // mismatch remains - which is why the bug survives in any deployment
        // or fixture that ever had exactly one module.
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('booking.access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: ['booking.access'],
          ),
          isEmpty,
        );
      });
    });
  });
}
