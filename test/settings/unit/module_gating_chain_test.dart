import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/admin/providers/is_admin_provider.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/settings/providers/module_list_provider.dart';
import 'package:titan/super_admin/providers/is_super_admin_provider.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';
import 'package:titan/super_admin/providers/permission_name_list_provider.dart';
import 'package:titan/super_admin/providers/permissions_list_provider.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/user/providers/user_provider.dart';

import '../settings_test_doubles.dart';

/// Where the user is in the app when a permission arrives: `permissionsPost`
/// adds a GROUP permission, and the group id is what `userHasPermission`
/// compares, so this stands in for "the backend says this group may book".
const bookingGroupId = 'g-booking';

/// The whole chain, none of it stubbed above the three leaf inputs:
///
/// ```
/// permissionsProvider + permissionsNamesListProvider + asyncUserProvider
///   -> moduleRootListProvider -> computeUserModuleRoots -> loadModules
///   -> modulesProvider
/// ```
///
/// Every other module test stubs `moduleRootListProvider` outright, so the
/// seam where ledger #55's bug lives — the join between the two backend
/// payloads, and between a bare word and a route root — had no test at all.
/// The fakes here are only the user, the permissions and the catalog; the
/// gating itself is the real production code.
ProviderContainer makeChainContainer({
  required List<CorePermission> permissions,
  required List<String> catalog,
  List<CoreGroupSimple> groups = const [
    CoreGroupSimple(id: bookingGroupId, name: 'Booking team'),
  ],
}) {
  final user = CoreUser.empty().copyWith(
    accountType: enums.AccountType.student,
    groups: groups,
  );
  return ProviderContainer(
    overrides: [
      loggerProvider.overrideWithValue(MockLogger()),
      userProvider.overrideWithValue(CoreUser.empty()),
      isAdminProvider.overrideWithValue(false),
      isSuperAdminProvider.overrideWithValue(false),
      asyncUserProvider.overrideWith(() => _StaticUserNotifier(user)),
      permissionsProvider.overrideWith(
        () => _StaticPermissionsNotifier(permissions),
      ),
      permissionsNamesListProvider.overrideWith(
        () => _StaticCatalogNotifier(catalog),
      ),
    ],
  );
}

class _StaticUserNotifier extends UserNotifier {
  _StaticUserNotifier(this.user);
  final CoreUser user;
  @override
  AsyncValue<CoreUser> build() => AsyncValue.data(user);
}

class _StaticPermissionsNotifier extends PermissionsNotifier {
  _StaticPermissionsNotifier(this.permissions);
  final List<CorePermission> permissions;
  @override
  AsyncValue<List<CorePermission>> build() => AsyncValue.data(permissions);
}

class _StaticCatalogNotifier extends PermissionsNamesListNotifier {
  _StaticCatalogNotifier(this.names);
  final List<String> names;
  @override
  AsyncValue<List<String>> build() => AsyncValue.data(names);
}

/// The roots the user can actually navigate to once the chain has run.
Future<List<String>> visibleRoots(ProviderContainer container) async {
  // Riverpod 3 auto-disposes providers without listeners, and saveModules'
  // fire-and-forget SharedPreferences callback then hits a disposed ref. An
  // active listener keeps the notifier alive.
  container.listen(modulesProvider, (_, _) {});

  // Reading the provider runs `build()`, which itself calls `loadModules` off
  // `moduleRootListProvider` — asynchronously, across a SharedPreferences
  // await. That call has to finish before the explicit one below, or it lands
  // last and overwrites the state this file asserts on. Draining the event
  // loop first is what makes the order deterministic.
  container.read(modulesProvider);
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }

  final roots = container.read(moduleRootListProvider).requireValue;
  await container
      .read(modulesProvider.notifier)
      .loadModules(roots.map((root) => '/$root').toList());
  return container.read(modulesProvider).map((m) => m.root.toString()).toList();
}

/// `loadModules` appends the Settings module unconditionally, so it is present
/// even for a user with no grants at all. Comparing against it is how these
/// tests say "nothing else came back".
bool onlySettings(List<String> roots) => roots.every((r) => r == '/settings');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  CorePermission groupPermission(String name) => CorePermission(
    permissionName: name,
    groups: const [bookingGroupId],
    accountTypes: const [],
  );

  group('the FULL-name shape: every grant reaches its module', () {
    test('a valid grant produces its module', () async {
      final container = makeChainContainer(
        permissions: [groupPermission('booking.access')],
        catalog: const ['booking.access', 'amap.access'],
      );
      addTearDown(container.dispose);

      final roots = await visibleRoots(container);

      // The catalog lists booking.access and the backend says this user's
      // group holds it — before #56 was fixed this returned Settings only.
      expect(roots, contains('/booking'));
      expect(roots, isNot(contains('/amap')));
    });

    test('two valid grants produce both modules', () async {
      final container = makeChainContainer(
        permissions: [
          groupPermission('booking.access'),
          groupPermission('amap.access'),
        ],
        catalog: const ['booking.access', 'amap.access'],
      );
      addTearDown(container.dispose);

      expect(await visibleRoots(container), containsAll(['/booking', '/amap']));
    });

    test('a single-module catalog resolves as well', () async {
      final container = makeChainContainer(
        permissions: [groupPermission('booking.access')],
        catalog: const ['booking.access'],
      );
      addTearDown(container.dispose);

      expect(await visibleRoots(container), contains('/booking'));
    });

    test('the user selecting the module in settings is honoured', () async {
      // The severity claim, tested. `loadModules` shows a module only when it
      // is BOTH in the persisted selection AND in the granted roots, so a user
      // who goes into settings and switches booking ON sees it only because
      // the grant half now works too.
      SharedPreferences.setMockInitialValues({
        'modules': ['/booking'],
        'allModules': ['/booking', '/amap', '/vote'],
      });
      final container = makeChainContainer(
        permissions: [groupPermission('booking.access')],
        catalog: const ['booking.access', '/amap', '/vote'],
      );
      addTearDown(container.dispose);

      final roots = await visibleRoots(container);

      expect(roots, contains('/booking'));
      expect(roots, isNot(contains('/vote')));
    });
  });

  group('the BARE-name shape', () {
    test('an unambiguous bare grant resolves to its only module', () async {
      // A single-module catalog leaves `access` with one meaning, so the bare
      // grant is still honoured.
      final container = makeChainContainer(
        permissions: [groupPermission('access')],
        catalog: const ['booking.access'],
      );
      addTearDown(container.dispose);

      expect(await visibleRoots(container), contains('/booking'));
    });

    test('a bare grant two modules claim grants nothing', () async {
      // Before #56 both catalog entries collided on the single key `access`,
      // so this silently granted amap, the last one written. Now the ambiguity
      // is refused rather than guessed at.
      final container = makeChainContainer(
        permissions: [groupPermission('access')],
        catalog: const ['booking.access', 'amap.access'],
      );
      addTearDown(container.dispose);

      final roots = await visibleRoots(container);

      expect(
        onlySettings(roots),
        isTrue,
        reason: 'a bare grant yielded $roots',
      );
    });
  });

  group('the catalog prefix must equal a route root', () {
    // A second failure mode, independent of the key mismatch:
    // `computeUserModuleRoots` returns the module root and `loadModules`
    // compares it to `Module.root`, which is a route. Two prefixes in the
    // shipped app do not match their module's root, so those modules could
    // never be granted by any permission, in any permission shape.
    test('a raffle grant resolves to the /tombola module', () async {
      final container = makeChainContainer(
        permissions: [groupPermission('raffle.access')],
        catalog: const ['raffle.access'],
      );
      addTearDown(container.dispose);

      // The chain resolves the ROUTE root, not the catalog prefix...
      expect(container.read(moduleRootListProvider).requireValue, ['tombola']);
      // ...so the module is visible.
      expect(await visibleRoots(container), contains('/tombola'));
    });

    test('a seed-library grant resolves to the /seed_library module', () async {
      // The same mismatch with a different character: the lib folder is
      // `seed-library`, the route is `/seed_library`.
      final container = makeChainContainer(
        permissions: [groupPermission('seed-library.access')],
        catalog: const ['seed-library.access'],
      );
      addTearDown(container.dispose);

      expect(container.read(moduleRootListProvider).requireValue, [
        'seed_library',
      ]);
      expect(await visibleRoots(container), contains('/seed_library'));
    });
  });

  group('the "access" filter', () {
    test('a name that merely contains "access" grants nothing', () async {
      // `contains('access')` also accepted `accessibility`,
      // `no_access_revoked` and `bypass_access_control`. Masked by #56 while
      // every lookup missed; with the lookup fixed the filter had to become a
      // suffix test or this would be a live grant-shaped hole.
      final container = makeChainContainer(
        permissions: [groupPermission('accessibility')],
        catalog: const ['booking.access', 'accessibility'],
      );
      addTearDown(container.dispose);

      final roots = await visibleRoots(container);

      expect(
        onlySettings(roots),
        isTrue,
        reason: 'accessibility granted $roots',
      );
    });
  });
}
