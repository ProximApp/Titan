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
/// Writing those tests turned up a production defect (bug #56, fixed 2026-10).
/// `buildPermissionToModuleRootMap` keyed its map by the name with the module
/// prefix STRIPPED, while `computeUserModuleRoots` looked it up with the FULL
/// name, so:
///
///  - FULL name (`booking.access`) — every lookup missed and every module was
///    dropped, leaving the user Settings and nothing else;
///  - BARE name (`access`) — every module collided on the one key, so a grant
///    resolved to whichever module was listed LAST.
///
/// The fix records the full name as the primary key and keeps a bare key only
/// while it is unambiguous, tightens the access filter to a suffix test, and
/// maps catalog prefixes that are not their module's route root. The cases
/// below are the fixed contract.
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
    test('a module-prefixed name is keyed by both of its names', () {
      expect(buildPermissionToModuleRootMap(['booking.access']), {
        'booking.access': 'booking',
        'access': 'booking',
      });
    });

    test('a name without a dot is skipped entirely', () {
      // `continue`, not a map entry with an empty root: an unqualified
      // permission cannot be attributed to a module.
      final map = buildPermissionToModuleRootMap(['admin', 'booking.access']);

      expect(map.containsKey('admin'), isFalse);
      expect(map, {'booking.access': 'booking', 'access': 'booking'});
    });

    test('an empty catalog produces an empty map', () {
      // The state every shell used to hand it, and the reason this function
      // was untested rather than merely unexercised.
      expect(buildPermissionToModuleRootMap(const []), isEmpty);
    });

    test('the split is at the FIRST dot, not the last', () {
      // `indexOf('.')` finds the first one, so `a.b.access` is the module `a`
      // holding `b.access`.
      expect(buildPermissionToModuleRootMap(['a.b.access']), {
        'a.b.access': 'a',
        'b.access': 'a',
      });
    });

    test('same-named permissions keep one full key each, and lose the bare one', () {
      // The old map collapsed all three onto the single key `access`, last
      // writer winning. Now each module keeps its own full-name entry, and the
      // bare name — which three modules claim — is dropped rather than
      // silently granting `amap` to a booking grant.
      final map = buildPermissionToModuleRootMap([
        'booking.access',
        'feed.access',
        'amap.access',
      ]);

      expect(map, {
        'booking.access': 'booking',
        'feed.access': 'feed',
        'amap.access': 'amap',
      });
      expect(map.containsKey('access'), isFalse);
    });

    test(
      'a catalog prefix that is not the route root maps to the route root',
      () {
        // `RaffleRouter.root` is `/tombola` and `SeedLibraryRouter.root` is
        // `/seed_library`; the catalog spells them after the folder, so without
        // the table a `raffle.access` grant would name a root no module has.
        expect(buildPermissionToModuleRootMap(['raffle.access']), {
          'raffle.access': 'tombola',
          'access': 'tombola',
        });
        expect(buildPermissionToModuleRootMap(['seed-library.access']), {
          'seed-library.access': 'seed_library',
          'access': 'seed_library',
        });
        // A prefix that already IS the route root is passed through.
        expect(moduleRouteRoot('booking'), 'booking');
      },
    );
  });

  group('isModuleAccessPermission', () {
    test('accepts the bare word and the full name', () {
      expect(isModuleAccessPermission('access'), isTrue);
      expect(isModuleAccessPermission('booking.access'), isTrue);
    });

    test('rejects names that merely contain "access"', () {
      // The filter used to be `contains('access')`, which also accepted
      // these three — masked only by the lookup bug above. Fixing the lookup
      // without tightening this would have turned it into a live grant.
      expect(isModuleAccessPermission('accessibility'), isFalse);
      expect(isModuleAccessPermission('no_access_revoked'), isFalse);
      expect(isModuleAccessPermission('bypass_access_control'), isFalse);
      expect(isModuleAccessPermission('booking.write'), isFalse);
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

    group('a grant resolves to the module it names (bug #56)', () {
      test('a FULL permission name resolves to its own module', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('booking.access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: catalog,
          ),
          ['booking'],
        );
      });

      test('and does not resolve to whichever module came last', () {
        // The old behaviour was `['feed']`: every module collided on `access`
        // and the last catalog entry overwrote the rest.
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('booking.access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: ['booking.access', 'feed.access'],
          ),
          isNot(contains('feed')),
        );
      });

      test('a single-module catalog resolves too', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('booking.access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: ['booking.access'],
          ),
          ['booking'],
        );
      });

      test('several grants resolve to several modules', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('booking.access', types: [enums.AccountType.staff]),
              permission('amap.access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: catalog,
          ),
          ['amap', 'booking'],
        );
      });

      test('a BARE grant is accepted while its meaning is unambiguous', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: ['booking.access'],
          ),
          ['booking'],
        );
      });

      test('an AMBIGUOUS bare grant grants nothing instead of a guess', () {
        // Two modules claim the bare name `access`; picking one would hand a
        // booking grant the amap module.
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: ['booking.access', 'amap.access'],
          ),
          isEmpty,
        );
      });

      test('a raffle grant resolves to the /tombola module', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission('raffle.access', types: [enums.AccountType.staff]),
            ],
            permissionCatalog: ['raffle.access'],
          ),
          ['tombola'],
        );
      });

      test('a seed-library grant resolves to the /seed_library module', () {
        expect(
          computeUserModuleRoots(
            user: staff,
            permissions: [
              permission(
                'seed-library.access',
                types: [enums.AccountType.staff],
              ),
            ],
            permissionCatalog: ['seed-library.access'],
          ),
          ['seed_library'],
        );
      });
    });
  });
}
