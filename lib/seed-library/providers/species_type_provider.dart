import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/seed-library/class/species_type.dart';

final speciesTypeProvider = NotifierProvider<SpeciesTypeNotifier, SpeciesType>(
  () => SpeciesTypeNotifier(),
);

class SpeciesTypeNotifier extends Notifier<SpeciesType> {
  @override
  SpeciesType build() {
    return SpeciesType(name: "");
  }

  void setType(SpeciesType i) {
    state = i;
  }
}
