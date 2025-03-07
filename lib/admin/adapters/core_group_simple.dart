import 'package:titan/generated/openapi.models.swagger.dart';

extension $CoreGroupSimple on CoreGroupSimple {
  CoreGroupUpdate toCoreGroupUpdate() {
    return CoreGroupUpdate(name: name, description: description);
  }
}
