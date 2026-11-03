import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

/// The admin module's own test doubles and builders: every admin test that
/// needs a pre-seeded group list or membership state takes them from here
/// instead of rebuilding the class (the group-list fake was copied verbatim
/// into two widget tests, the membership one into a unit and a widget test).
///
/// Fixtures shared by several files of ONE module live here; a helper only
/// one file needs stays in that file. Platform-wide stubs (pickers, route
/// mocks, url_launcher) belong in `test/shared/*_stub.dart` instead.
class GroupListFake extends GroupListNotifier {
  GroupListFake(this.groups);

  final List<CoreGroupSimple> groups;

  @override
  AsyncValue<List<CoreGroupSimple>> build() => AsyncValue.data(groups);
}

/// The membership list in its loading state: the spinner branch of the
/// detail page's members section.
class MembersNotifier extends AssociationMembershipMembersNotifier {
  @override
  AsyncValue<List<UserMembershipComplete>> build() =>
      const AsyncValue.loading();
}
