import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/paiement/class/structure.dart';

class StructureNotifier extends Notifier<Structure> {
  @override
  Structure build() {
    return Structure.empty();
  }

  void setStructure(Structure structure) {
    state = structure;
  }

  void resetStructure() {
    state = Structure.empty();
  }
}

final structureProvider = NotifierProvider<StructureNotifier, Structure>(
  () => StructureNotifier(),
);
