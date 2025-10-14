import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

final plantSimpleProvider = NotifierProvider<PlantSimpleNotifier, PlantSimple>(
  () => PlantSimpleNotifier(),
);

class PlantSimpleNotifier extends Notifier<PlantSimple> {
  @override
  PlantSimple build() {
    return EmptyModels.empty<PlantSimple>();
  }

  void setPlant(PlantSimple i) {
    state = i;
  }
}
