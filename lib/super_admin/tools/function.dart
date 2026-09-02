import 'package:flutter/widgets.dart';
import 'package:titan/super_admin/tools/constants.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/functions.dart';

String getSchoolNameFromId(String id, String name, BuildContext context) {
  if (id == SchoolIdConstant.noSchool.value) {
    return AppLocalizations.of(context)!.adminNoSchool;
  }
  if (id == SchoolIdConstant.eclSchool.value) {
    return getBaseSchoolName();
  }
  return name;
}

String capitalizePermissionName(String permissionName) {
  return permissionName
      .split('_')
      .map(
        (word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word,
      )
      .join(' ');
}

String snakeToCamelCase(String input) {
  final parts = input.split('_');
  final buffer = StringBuffer(parts.first);

  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.isEmpty) continue;
    buffer.write(part[0].toUpperCase());
    buffer.write(part.substring(1));
  }

  return buffer.toString();
}
