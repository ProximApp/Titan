import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/structure.dart';
import 'package:titan/paiement/repositories/structures_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class StructureListNotifier extends ListNotifier<Structure> {
  StructuresRepository get structuresRepository =>
      ref.watch(structuresRepositoryProvider);

  @override
  AsyncValue<List<Structure>> build() {
    getStructures();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Structure>>> getStructures() async {
    return await loadList(structuresRepository.getStructures);
  }

  Future<bool> updateStructure(Structure structure) async {
    return await update(
      structuresRepository.updateStructure,
      (structures, structure) =>
          structures
            ..[structures.indexWhere((s) => s.id == structure.id)] = structure,
      structure,
    );
  }

  Future<bool> deleteStructure(Structure structure) async {
    return await delete(
      (id) => structuresRepository.deleteStructure(id),
      (structures, structure) =>
          structures..removeWhere((s) => s.id == structure.id),
      structure.id,
      structure,
    );
  }

  Future<bool> createStructure(Structure structure) async {
    return await add(structuresRepository.createStructure, structure);
  }
}

final structureListProvider =
    NotifierProvider<StructureListNotifier, AsyncValue<List<Structure>>>(
      StructureListNotifier.new,
    );
