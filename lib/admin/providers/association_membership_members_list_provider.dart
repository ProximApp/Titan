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
    UserMembershipComplete userAssociationMembership,
    CoreUserSimple user,
  ) async {
    return (await associationMembershipRepository
            .membershipsAssociationMembershipIdAddBatchPost(
              associationMembershipId:
                  userAssociationMembership.associationMembershipId,
              body: [
                MembershipUserMappingEmail(
                  userEmail: user.email,
                  startDate: userAssociationMembership.startDate,
                  endDate: userAssociationMembership.endDate,
                ),
              ],
            ))
        .isSuccessful;
  }

  Future<bool> updateMember(
    UserMembershipComplete associationMembership,
    AppCoreMembershipsSchemasMembershipsMembershipBase body,
  ) async {
    return await update(
      () async => associationMembershipRepository
          .membershipsAssociationMembershipIdPatch(
            associationMembershipId: associationMembership.id,
            body: body,
          ),
      (membership) => membership.id,
      associationMembership,
    );
  }

  Future<bool> deleteMember(
    UserMembershipComplete associationMembership,
  ) async {
    return await delete(
      () async => associationMembershipRepository
          .membershipsAssociationMembershipIdDelete(
            associationMembershipId: associationMembership.id,
          ),
      (membership) => membership.id,
      associationMembership.id,
    );
  }
}

final associationMembershipMembersProvider =
    NotifierProvider<
      AssociationMembershipMembersNotifier,
      AsyncValue<List<UserMembershipComplete>>
    >(() => AssociationMembershipMembersNotifier());
