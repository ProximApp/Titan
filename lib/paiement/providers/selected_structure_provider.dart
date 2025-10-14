import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class SelectedStructureNotifier extends Notifier<Structure> {
  @override
  Structure build() {
    return EmptyModels.empty<Structure>();
  }

  void setStructure(Structure structure) {
    state = structure;
  }
}

final selectedStructureProvider =
    NotifierProvider<SelectedStructureNotifier, Structure>(
      SelectedStructureNotifier.new,
    );
