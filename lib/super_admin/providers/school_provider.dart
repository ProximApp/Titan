import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class SchoolNotifier extends Notifier<CoreSchool> {
  @override
  CoreSchool build() {
    return EmptyModels.empty<CoreSchool>();
  }

  void setSchool(CoreSchool school) {
    state = school;
  }
}

final schoolProvider = NotifierProvider<SchoolNotifier, CoreSchool>(
  SchoolNotifier.new,
);
