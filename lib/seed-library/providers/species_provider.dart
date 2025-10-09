import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/seed-library/class/species.dart';

final speciesProvider = NotifierProvider<SpeciesNotifier, Species>(
  SpeciesNotifier.new,
);

class SpeciesNotifier extends Notifier<Species> {
  @override
  Species build() => Species.empty();

  void setSpecies(Species i) {
    state = i;
  }
}
