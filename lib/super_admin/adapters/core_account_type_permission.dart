import 'package:titan/generated/openapi.models.swagger.dart';

extension $CoreAccountTypePermission on CoreAccountTypePermission {
  CorePermission toCorePermission() {
    return CorePermission(
      permissionName: permissionName,
      groups: [],
      accountTypes: [accountType],
    );
  }
}
