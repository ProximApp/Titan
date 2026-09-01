import 'package:titan/generated/openapi.models.swagger.dart';

extension ApplicantName on Applicant {
  String getName() {
    if (nickname == null) {
      return '$firstname $name';
    }
    return '$nickname ($firstname $name)';
  }
}
