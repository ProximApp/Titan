import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class StructureManagerProvider extends Notifier<CoreUserSimple> {
  @override
  CoreUserSimple build() {
    return EmptyModels.empty<CoreUserSimple>();
  }

  void setUser(CoreUserSimple user) {
    state = user;
  }
}

final structureManagerProvider =
    NotifierProvider<StructureManagerProvider, CoreUserSimple>(
      () => StructureManagerProvider(),
    );
