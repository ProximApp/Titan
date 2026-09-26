import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/association_membership_filtered_members_provider.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:titan/admin/providers/research_filter_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

/// Stands in for the real [AssociationMembershipMembersNotifier], whose
/// build() fetches from the repository.
class FakeMembersNotifier extends AssociationMembershipMembersNotifier {
  FakeMembersNotifier(this.members);

  final List<UserMembershipComplete> members;

  @override
  AsyncValue<List<UserMembershipComplete>> build() => AsyncValue.data(members);
}

class _LoadingMembersNotifier extends AssociationMembershipMembersNotifier {
  @override
  AsyncValue<List<UserMembershipComplete>> build() =>
      const AsyncValue.loading();
}

class FakeFilterNotifier extends FilterNotifier {
  FakeFilterNotifier(this.filter);

  final String filter;

  @override
  String build() => filter;
}

void main() {
  group('associationMembershipFilteredListProvider', () {
    test('filters members by name ignoring accents and case', () {
      final members = [
        UserMembershipComplete.empty().copyWith(
          user: CoreUserSimple.empty().copyWith(
            firstname: 'Amélie',
            name: 'Dupont',
          ),
        ),
        UserMembershipComplete.empty().copyWith(
          user: CoreUserSimple.empty().copyWith(
            firstname: 'Bob',
            name: 'Jones',
          ),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          associationMembershipMembersProvider.overrideWith(
            () => FakeMembersNotifier(members),
          ),
          filterProvider.overrideWith(() => FakeFilterNotifier('amelie')),
        ],
      );

      final filtered = container.read(
        associationMembershipFilteredListProvider,
      );

      expect(filtered, hasLength(1));
      expect(filtered.single.user.firstname, 'Amélie');

      container.dispose();
    });

    test('returns an empty list while the members are loading', () {
      final container = ProviderContainer(
        overrides: [
          associationMembershipMembersProvider.overrideWith(
            _LoadingMembersNotifier.new,
          ),
          filterProvider.overrideWith(() => FakeFilterNotifier('')),
        ],
      );

      expect(
        container.read(associationMembershipFilteredListProvider),
        isEmpty,
      );

      container.dispose();
    });
  });
}
