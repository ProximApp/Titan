import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/seed-library/class/species_type.dart';
import 'package:titan/seed-library/tools/constants.dart';

final speciesTypeFilterProvider = NotifierProvider<FilterNotifier, SpeciesType>(
  () => FilterNotifier(),
);

class FilterNotifier extends Notifier<SpeciesType> {
  @override
  SpeciesType build() {
    return SpeciesType(name: SeedLibraryTextConstants.all);
  }

  void setFilter(SpeciesType i) {
    state = i;
  }
}
