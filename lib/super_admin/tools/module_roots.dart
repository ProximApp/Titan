import 'package:titan/generated/openapi.models.swagger.dart';

Map<String, String> buildPermissionToModuleRootMap(
  List<String> fullNameCatalog,
) {
  final map = <String, String>{};
  for (final fullName in fullNameCatalog) {
    final dotIndex = fullName.indexOf('.');
    if (dotIndex == -1) continue;
    final moduleRoot = fullName.substring(0, dotIndex);
    final permissionName = fullName.substring(dotIndex + 1);
    map[permissionName] = moduleRoot;
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
    if (!permission.permissionName.contains('access')) continue;
    if (!userHasPermission(user, permission)) continue;

    final backendRoot = permissionToModule[permission.permissionName];
    if (backendRoot == null) continue;

    moduleRoots.add(backendRoot);
  }

  return moduleRoots.toList()..sort();
}
