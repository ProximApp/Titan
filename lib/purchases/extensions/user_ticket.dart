import 'package:titan/generated/openapi.models.swagger.dart';

extension $UserTicket on UserTicket {
  String getName() {
    if (nickname == null) {
      return '$firstname $name';
    }
    return '$nickname ($firstname $name)';
  }
}
