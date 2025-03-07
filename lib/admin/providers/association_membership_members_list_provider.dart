import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class AssociationMembershipMembersNotifier
    extends ListNotifierAPI<UserMembershipComplete> {
  Openapi get associationMembershipRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<UserMembershipComplete>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<UserMembershipComplete>>>
  loadAssociationMembershipMembers(
    String associationMembershipId, {
    DateTime? minimalStartDate,
    DateTime? minimalEndDate,
    DateTime? maximalStartDate,
    DateTime? maximalEndDate,
  }) async {
    return await loadList(
      () async => associationMembershipRepository
          .membershipsAssociationMembershipIdMembersGet(
            associationMembershipId: associationMembershipId,
            minimalStartDate: minimalStartDate
                ?.toIso8601String()
                .split('T')
                .first,
            minimalEndDate: minimalEndDate?.toIso8601String().split('T').first,
            maximalStartDate: maximalStartDate
                ?.toIso8601String()
                .split('T')
                .first,
            maximalEndDate: maximalEndDate?.toIso8601String().split('T').first,
          ),
    );
  }

  Future<bool> addMember(
    UserAssociationMembershipBase userAssociationMembership,
    SimpleUser user,
  ) async {
    return await add(
      () async => associationMembershipRepository
          .membershipsAssociationMembershipIdAddBatchPost(userAssociationMembership),
      UserAssociationMembership(
        id: userAssociationMembership.id,
        associationMembershipId:
            userAssociationMembership.associationMembershipId,
        userId: userAssociationMembership.userId,
        startDate: userAssociationMembership.startDate,
        endDate: userAssociationMembership.endDate,
        user: user,
      ),
    );
  }

  Future<bool> updateMember(
    UserAssociationMembership associationMembership,
  ) async {
    return await update(
      (associationMembership) async => associationMembershipUserRepository
          .updateUserMembership(associationMembership),
      (userAssociationMemberships, membership) => userAssociationMemberships
        ..[userAssociationMemberships.indexWhere(
              (g) => g.id == membership.id,
            )] =
            membership,
      associationMembership,
    );
  }

  Future<bool> deleteMember(
    UserAssociationMembership associationMembership,
  ) async {
    return await delete(
      (membershipId) async => associationMembershipUserRepository
          .deleteUserMembership(membershipId),
      (userAssociationMemberships, membership) =>
          userAssociationMemberships..remove(associationMembership),
      associationMembership.id,
      associationMembership,
    );
  }
}

final associationMembershipMembersProvider =
    NotifierProvider<
      AssociationMembershipMembersNotifier,
      AsyncValue<List<UserMembershipComplete>>
    >(() => AssociationMembershipMembersNotifier());
