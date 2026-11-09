import 'package:titan/generated/openapi.models.swagger.dart';

/// Catalog prefixes (the word before the dot in `<prefix>.<permission>` of a
/// permission catalog entry) that are NOT their module's route root.
/// `ModulesNotifier.loadModules` compares a grant against `Module.root`, so a
/// prefix missing from this table must already be the route root minus its
/// leading slash. Both entries below are real: `RaffleRouter.root` is
/// `/tombola` and `SeedLibraryRouter.root` is `/seed_library`, so a grant
/// spelled after the module's folder (`raffle`, `seed-library`) would resolve
/// to a root no module has — and the module would stay invisible to every
/// user, whatever their permissions said.
const Map<String, String> moduleRouteRootOverrides = {
  'raffle': 'tombola',
  'seed-library': 'seed_library',
};

/// The route root (no leading slash) a catalog prefix grants.
String moduleRouteRoot(String prefix) =>
    moduleRouteRootOverrides[prefix] ?? prefix;

/// A module access permission is the bare word `access` or the full name
/// `<module>.access`. A substring test (`contains('access')`) would also
/// accept `accessibility`, `no_access_revoked` and `bypass_access_control`,
/// none of which grant a module.
bool isModuleAccessPermission(String permissionName) =>
    permissionName == 'access' || permissionName.endsWith('.access');

/// Maps permission names to the module route root they grant.
///
/// Catalog entries are `<prefix>.<permission>` (`booking.access`). A user's
/// grants arrive as `CorePermission.permissionName`, either with the module
/// prefix (`booking.access`) or bare (`access`), so both keys are recorded:
/// the full name is the primary key, and a bare name is only recorded while
/// its meaning is unambiguous — on a collision (`booking.access` +
/// `amap.access` both claiming `access`) the bare key is dropped instead of
/// silently granting whichever module was listed last.
Map<String, String> buildPermissionToModuleRootMap(
  List<String> fullNameCatalog,
) {
  final map = <String, String>{};
  final ambiguous = <String>{};

  for (final fullName in fullNameCatalog) {
    final dotIndex = fullName.indexOf('.');
    if (dotIndex == -1) continue;
    final root = moduleRouteRoot(fullName.substring(0, dotIndex));
    final bareName = fullName.substring(dotIndex + 1);
    map[fullName] = root;

    final previous = map[bareName];
    if (previous != null && previous != root) {
      ambiguous.add(bareName);
    } else {
      map[bareName] = root;
    }
  }

  for (final bareName in ambiguous) {
    map.remove(bareName);
  }
  return map;
}

bool userHasPermission(CoreUser user, CorePermission permission) {
  final userGroupIds = (user.groups ?? []).map((group) => group.id).toSet();
  if (permission.groups.any(userGroupIds.contains)) {
    return true;
  }
  return permission.accountTypes.contains(user.accountType);
}

List<String> computeUserModuleRoots({
  required CoreUser user,
  required List<CorePermission> permissions,
  required List<String> permissionCatalog,
}) {
  final permissionToModule = buildPermissionToModuleRootMap(permissionCatalog);
  final moduleRoots = <String>{};

  for (final permission in permissions) {
    if (!isModuleAccessPermission(permission.permissionName)) continue;
    if (!userHasPermission(user, permission)) continue;

    final backendRoot = permissionToModule[permission.permissionName];
    if (backendRoot == null) continue;

    moduleRoots.add(backendRoot);
  }

  return moduleRoots.toList()..sort();
}
