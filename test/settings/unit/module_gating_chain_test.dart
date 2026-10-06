import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

class MockLogger extends Mock implements Logger {}

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
  // loop first is what makes the order deterministic; without it a bare-name
  // grant reads as "no modules" and the test would blame the bug for a race
  // in the harness.
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

  group('the FULL-name shape: every lookup misses', () {
    test('KNOWN BUG: valid grants produce no modules at all', () async {
      final container = makeChainContainer(
        permissions: [groupPermission('booking.access')],
        catalog: const ['booking.access', 'amap.access'],
      );
      addTearDown(container.dispose);

      final roots = await visibleRoots(container);

      // The catalog lists booking.access, the backend says this user's group
      // holds it, and the user still gets nothing but Settings. This is the
      // end-to-end shape of bug #56: the map is keyed by the stripped name
      // and read with the full one, so every lookup misses.
      expect(
        onlySettings(roots),
        isTrue,
        reason: 'a granted booking.access yielded $roots',
      );
    });

    test('KNOWN BUG: two valid grants together still produce nothing', () async {
      // The whole bug in one case: two real grants, both in the catalog, both
      // belonging to a group the user is in — and Settings only. The fix must
      // turn this into containsAll(['/booking', '/amap']); it is written as
      // the current outcome so the suite stays green and the change is
      // deliberate rather than a drive-by.
      final container = makeChainContainer(
        permissions: [
          groupPermission('booking.access'),
          groupPermission('amap.access'),
        ],
        catalog: const ['booking.access', 'amap.access'],
      );
      addTearDown(container.dispose);

      final roots = await visibleRoots(container);

      expect(
        onlySettings(roots),
        isTrue,
        reason:
            'correct behaviour is containsAll([/booking, /amap]); the map key '
            'and the lookup key disagree, so neither resolves (bug #56)',
      );
    });

    test('KNOWN BUG: a single-module catalog still yields nothing', () async {
      // No collision is possible with one module, which is why the bug can
      // hide in a small deployment or a trimmed fixture: only the key
      // mismatch is left.
      final container = makeChainContainer(
        permissions: [groupPermission('booking.access')],
        catalog: const ['booking.access'],
      );
      addTearDown(container.dispose);

      expect(onlySettings(await visibleRoots(container)), isTrue);
    });

    test(
      'KNOWN BUG: the user selecting the module in settings cannot fix it',
      () async {
        // The severity claim, tested. `loadModules` shows a module only when it
        // is BOTH in the persisted selection AND in the granted roots, so a
        // user who goes into settings and switches booking ON still does not
        // see it - the selection is the half that works, and there is no user
        // action that can supply the other half.
        //
        // The selection is seeded here rather than produced by a first launch,
        // so the test says what it means: this is the state after the user has
        // already been to settings and enabled everything.
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

        expect(
          roots,
          isNot(contains('/booking')),
          reason:
              'the selection says booking is on and the backend says the group '
              'holds booking.access; the grant list is empty anyway (bug #56), '
              'and no settings toggle can change that',
        );
        expect(onlySettings(roots), isTrue);
      },
    );
  });

  group('the BARE-name shape: the grant silently resolves elsewhere', () {
    test(
      'KNOWN BUG: a bare grant lands the user in the LAST module listed',
      () async {
        // The worse of the two shapes, because it is silent: the user DOES get
        // a module, just not the one they were granted. A bare `access` written
        // for booking resolves to amap, and the navbar offers amap as though
        // that were correct. Nothing in the UI distinguishes this from a
        // genuine amap grant.
        final container = makeChainContainer(
          permissions: [groupPermission('access')],
          catalog: const ['booking.access', 'amap.access'],
        );
        addTearDown(container.dispose);

        final roots = await visibleRoots(container);

        expect(
          roots,
          contains('/amap'),
          reason:
              'both catalog entries collide on the single key access, so the '
              'last one wrote it. A booking grant must not produce amap.',
        );
        expect(
          roots,
          isNot(contains('/booking')),
          reason: 'the module the user actually holds is the one that is lost',
        );
      },
    );
  });

  group('the catalog prefix must equal a route root', () {
    // A third failure mode, independent of the key mismatch:
    // `computeUserModuleRoots` returns the BARE prefix and `loadModules`
    // compares it to `Module.root`, which is a route. Two prefixes in the
    // shipped app do not match their module's root, so those modules can
    // never be granted by any permission, in any permission shape.
    test(
      'KNOWN BUG: "raffle" is not a module root - the route is /tombola',
      () async {
        final container = makeChainContainer(
          permissions: [groupPermission('access')],
          catalog: const ['raffle.access'],
        );
        addTearDown(container.dispose);

        // The chain resolves the root...
        expect(container.read(moduleRootListProvider).requireValue, ['raffle']);
        // ...and no shipped module has that root, so nothing is visible.
        expect(
          onlySettings(await visibleRoots(container)),
          isTrue,
          reason:
              'RaffleRouter.root is /tombola; a raffle.access grant produces the '
              'word "raffle", which matches no Module.root. The catalog prefix '
              'must be the route root minus its slash.',
        );
      },
    );

    test('KNOWN BUG: "seed-library" vs the /seed_library route', () async {
      // The same mismatch with a different character: the lib folder is
      // `seed-library`, the route is `/seed_library`, so a catalog entry
      // spelled either way resolves to a root that does not exist.
      final container = makeChainContainer(
        permissions: [groupPermission('access')],
        catalog: const ['seed-library.access'],
      );
      addTearDown(container.dispose);

      expect(container.read(moduleRootListProvider).requireValue, [
        'seed-library',
      ]);
      expect(
        onlySettings(await visibleRoots(container)),
        isTrue,
        reason:
            'SeedLibraryRouter.root is /seed_library; a hyphenated prefix '
            'produces a root no module has.',
      );
    });

    test('a prefix that IS a route root does resolve end to end', () async {
      // The control for the two above, so they cannot be passing for an
      // unrelated reason: `booking` -> `/booking` really does come through
      // the whole chain. It needs the BARE permission name to get past bug
      // #56, which is the point — it isolates the second failure mode.
      final container = makeChainContainer(
        permissions: [groupPermission('access')],
        catalog: const ['booking.access'],
      );
      addTearDown(container.dispose);

      expect(
        await visibleRoots(container),
        contains('/booking'),
        reason: 'with one module and a bare name, nothing else can go wrong',
      );
    });
  });

  group('the "access" filter', () {
    test('KNOWN BUG: it is a substring test, not a suffix test', () async {
      // `permission.permissionName.contains('access')` also accepts
      // `accessibility`, `no_access_revoked` and `bypass_access_control` —
      // any name carrying the letters anywhere. Today that is masked,
      // because such a name also fails the (broken) lookup, so nothing comes
      // back. Pinned now, BEFORE bug #56 is fixed, because fixing the key
      // without tightening this filter would turn it into a live
      // grant-shaped hole.
      final container = makeChainContainer(
        permissions: [groupPermission('accessibility')],
        catalog: const ['accessibility.access'],
      );
      addTearDown(container.dispose);

      expect(
        onlySettings(await visibleRoots(container)),
        isTrue,
        reason:
            'accessibility is not a module access permission; this passes only '
            'because the key mismatch hides it. Fixing #56 without changing '
            '.contains to a suffix check would make it a real grant.',
      );
    });
  });
}
