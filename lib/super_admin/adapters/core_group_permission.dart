import 'package:titan/generated/openapi.models.swagger.dart';

extension $CoreGroupPermission on CoreGroupPermission {
  CorePermission toCorePermission() {
    return CorePermission(
      permissionName: permissionName,
      groups: [groupId],
      accountTypes: [],
    );
  }
}
