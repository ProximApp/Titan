import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class SpeciesNotifier extends Notifier<SpeciesComplete> {
  @override
  SpeciesComplete build() => EmptyModels.empty<SpeciesComplete>();

  void setSpecies(SpeciesComplete i) {
    state = i;
  }
}

final speciesProvider = NotifierProvider<SpeciesNotifier, SpeciesComplete>(
  SpeciesNotifier.new,
);
