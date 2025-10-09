import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/association_membership_simple.dart';
import 'package:titan/admin/repositories/association_membership_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class AssociationMembershipListNotifier
    extends ListNotifier<AssociationMembership> {
  AssociationMembershipRepository get associationMembershipRepository =>
      ref.watch(associationMembershipRepositoryProvider);

  @override
  AsyncValue<List<AssociationMembership>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<AssociationMembership>>>
  loadAssociationMemberships() async {
    return await loadList(
      associationMembershipRepository.getAssociationMembershipList,
    );
  }

  Future<bool> createAssociationMembership(
    AssociationMembership associationMembership,
  ) async {
    return await add(
      associationMembershipRepository.createAssociationMembership,
      associationMembership,
    );
  }

  Future<bool> updateAssociationMembership(
    AssociationMembership associationMembership,
  ) async {
    return await update(
      associationMembershipRepository.updateAssociationMembership,
      (associationMemberships, associationMembership) => associationMemberships
        ..[associationMemberships.indexWhere(
              (g) => g.id == associationMembership.id,
            )] =
            associationMembership,
      associationMembership,
    );
  }

  Future<bool> deleteAssociationMembership(
    AssociationMembership associationMembership,
  ) async {
    return await delete(
      associationMembershipRepository.deleteAssociationMembership,
      (associationMemberships, associationMembership) =>
          associationMemberships
            ..removeWhere((i) => i.id == associationMembership.id),
      associationMembership.id,
      associationMembership,
    );
  }
}

final allAssociationMembershipListProvider =
    NotifierProvider<
      AssociationMembershipListNotifier,
      AsyncValue<List<AssociationMembership>>
    >(() => AssociationMembershipListNotifier());
