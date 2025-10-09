import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/phonebook/class/association_groupement.dart';
import 'package:titan/phonebook/repositories/association_groupement_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class AssociationGroupementListNotifier
    extends ListNotifier<AssociationGroupement> {
  final AssociationGroupementRepository associationGroupementRepository =
      AssociationGroupementRepository();

  @override
  AsyncValue<List<AssociationGroupement>> build() {
    final token = ref.watch(tokenProvider);
    associationGroupementRepository.setToken(token);
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<AssociationGroupement>>>
  loadAssociationGroupement() async {
    return await loadList(
      associationGroupementRepository.getAssociationGroupements,
    );
  }

  Future<bool> createAssociationGroupement(
    AssociationGroupement associationGroupement,
  ) async {
    return await add(
      associationGroupementRepository.createAssociationGroupement,
      associationGroupement,
    );
  }

  Future<bool> updateAssociationGroupement(
    AssociationGroupement associationGroupement,
  ) async {
    return await update(
      associationGroupementRepository.updateAssociationGroupement,
      (associationGroupements, associationGroupement) => associationGroupements
        ..[associationGroupements.indexWhere(
              (g) => g.id == associationGroupement.id,
            )] =
            associationGroupement,
      associationGroupement,
    );
  }

  Future<bool> deleteAssociationGroupement(
    AssociationGroupement associationGroupement,
  ) async {
    return await delete(
      associationGroupementRepository.deleteAssociationGroupement,
      (associationGroupements, associationGroupement) =>
          associationGroupements
            ..removeWhere((i) => i.id == associationGroupement.id),
      associationGroupement.id,
      associationGroupement,
    );
  }
}

final associationGroupementListProvider =
    NotifierProvider<
      AssociationGroupementListNotifier,
      AsyncValue<List<AssociationGroupement>>
    >(() => AssociationGroupementListNotifier());
