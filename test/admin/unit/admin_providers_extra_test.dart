import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/all_group_list_provider.dart';
import 'package:titan/admin/providers/association_membership_filtered_members_provider.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:titan/admin/providers/group_from_simple_group_provider.dart';
import 'package:titan/admin/providers/notification_provider.dart';
import 'package:titan/admin/providers/research_filter_provider.dart';
import 'package:titan/admin/providers/simple_groups_groups_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

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

/// Stands in for the real [GroupListNotifier], whose build() POSTs through
/// the repository; the simple-groups map only ever reads its data slot.
class FakeGroupListNotifier extends GroupListNotifier {
  FakeGroupListNotifier(this.groups);

  final AsyncValue<List<CoreGroupSimple>> groups;

  @override
  AsyncValue<List<CoreGroupSimple>> build() => groups;
}

class LoadingGroupListNotifier extends GroupListNotifier {
  @override
  AsyncValue<List<CoreGroupSimple>> build() => const AsyncValue.loading();
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

  group('filterProvider', () {
    test('starts empty and setFilter replaces the search term', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(filterProvider), '');
      container.read(filterProvider.notifier).setFilter('dupont');
      expect(container.read(filterProvider), 'dupont');
    });
  });

  group('simpleGroupsGroupsProvider', () {
    test('keys every loaded group by id with an unfetched slot', () {
      final groups = [
        CoreGroupSimple.empty().copyWith(id: 'g1', name: 'BDE'),
        CoreGroupSimple.empty().copyWith(id: 'g2', name: 'BDS'),
      ];
      final container = ProviderContainer(
        overrides: [
          allGroupListProvider.overrideWith(
            () => FakeGroupListNotifier(AsyncValue.data(groups)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final slots = container.read(simpleGroupsGroupsProvider);
      expect(slots.keys, unorderedEquals(['g1', 'g2']));
      expect(slots.values, everyElement(isNull));
    });

    test('is an empty map while the group list is loading', () {
      final container = ProviderContainer(
        overrides: [
          allGroupListProvider.overrideWith(LoadingGroupListNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(simpleGroupsGroupsProvider), isEmpty);
    });
  });

  group('groupFromSimpleGroupProvider', () {
    test('starts empty and gains, updates and loses entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(groupFromSimpleGroupProvider.notifier);

      expect(container.read(groupFromSimpleGroupProvider), isEmpty);

      notifier.addT('g1');
      expect(container.read(groupFromSimpleGroupProvider), {'g1': null});

      // Adding twice must not reset the slot that is already loaded.
      final full = CoreGroup.empty().copyWith(id: 'g1', name: 'BDE');
      notifier.setTData('g1', AsyncValue.data(full));
      notifier.addT('g1');
      expect(
        container.read(groupFromSimpleGroupProvider)['g1'],
        AsyncValue.data(full),
      );

      notifier.deleteT('g1');
      expect(container.read(groupFromSimpleGroupProvider), isEmpty);
    });

    test('loadTList opens a null slot per id and resetAll clears them', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(groupFromSimpleGroupProvider.notifier);

      notifier.loadTList(['g1', 'g2']);
      expect(container.read(groupFromSimpleGroupProvider), {
        'g1': null,
        'g2': null,
      });

      notifier.setTData(
        'g1',
        AsyncValue.data(CoreGroup.empty().copyWith(id: 'g1')),
      );
      notifier.resetAll();
      expect(container.read(groupFromSimpleGroupProvider), {
        'g1': null,
        'g2': null,
      });
    });
  });

  group('NotificationNotifier', () {
    late MockOpenapi repo;
    late ProviderContainer container;
    late NotificationNotifier notifier;
    final request = GroupNotificationRequest(
      groupId: 'g1',
      title: 'Sortie',
      content: 'Rendez-vous à 18h',
    );

    setUp(() {
      repo = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      notifier = container.read(notificationProvider.notifier);
      addTearDown(container.dispose);
    });

    test('sendNotification answers true on a 2xx', () async {
      when(() => repo.notificationSendPost(body: request))
          .thenAnswer((_) async => repo.okVoid());

      expect(await notifier.sendNotification(request), isTrue);
    });

    test('sendNotification answers false when the server refuses', () async {
      when(() => repo.notificationSendPost(body: request))
          .thenAnswer((_) async => repo.fail<void>(500));

      expect(await notifier.sendNotification(request), isFalse);
    });
  });
}
