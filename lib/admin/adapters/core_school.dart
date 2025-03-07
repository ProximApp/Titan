import 'package:titan/generated/openapi.models.swagger.dart';

extension $CoreSchool on CoreSchool {
  CoreSchoolUpdate toCoreSchoolUpdate() {
    return CoreSchoolUpdate(emailRegex: emailRegex, name: name);
  }
}
