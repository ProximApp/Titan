import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/assocation.dart';
import 'package:titan/admin/repositories/association_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class AssociationListNotifier extends ListNotifier<Association> {
  AssociationRepository get associationRepository =>
      ref.watch(associationRepositoryProvider);

  @override
  AsyncValue<List<Association>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Association>>> loadAssociations() async {
    return await loadList(associationRepository.getAssociationList);
  }

  Future<bool> createAssociation(Association association) async {
    return await add(associationRepository.createAssociation, association);
  }

  Future<bool> updateAssociation(Association association) async {
    return await update(
      associationRepository.updateAssociation,
      (associations, association) => associations
        ..[associations.indexWhere((g) => g.id == association.id)] =
            association,
      association,
    );
  }

  Future<bool> deleteAssociation(Association association) async {
    return await delete(
      associationRepository.deleteAssociation,
      (associations, association) =>
          associations..removeWhere((i) => i.id == association.id),
      association.id,
      association,
    );
  }

  void setAssociation(Association association) {
    state.whenData((d) {
      if (d.indexWhere((g) => g.id == association.id) == -1) return;
      state = AsyncValue.data(
        d..[d.indexWhere((g) => g.id == association.id)] = association,
      );
    });
  }
}

final associationListProvider =
    NotifierProvider<AssociationListNotifier, AsyncValue<List<Association>>>(
      () => AssociationListNotifier(),
    );
