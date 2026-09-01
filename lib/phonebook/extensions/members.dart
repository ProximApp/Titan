import 'package:titan/generated/openapi.models.swagger.dart';

extension MemberCompleteName on MemberComplete {
  String getName() {
    if (nickname == null) {
      return '$firstname $name';
    }
    return '$nickname ($firstname $name)';
  }
}
