import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/phonebook/providers/association_filtered_list_provider.dart';
import 'package:titan/phonebook/providers/association_groupement_list_provider.dart';
import 'package:titan/phonebook/providers/association_groupement_provider.dart';
import 'package:titan/phonebook/providers/association_list_provider.dart';
import 'package:titan/phonebook/providers/association_member_list_provider.dart';
import 'package:titan/phonebook/providers/association_member_sorted_list_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/providers/is_phonebook_admin_provider.dart';
import 'package:titan/phonebook/providers/research_filter_provider.dart';
import 'package:titan/phonebook/providers/roles_tags_provider.dart';
import 'package:titan/phonebook/tools/function.dart';
import 'package:titan/user/providers/user_provider.dart';

import '../../shared/fixtures.dart';
import '../phonebook_fixtures.dart' as fixtures;

AssociationComplete association(
  String id,
  String name, {
  String groupementId = '',
  int mandateYear = 2026,
}) => fixtures.association(
  id,
  name,
  groupementId: groupementId,
  mandateYear: mandateYear,
);

AssociationGroupement groupement(String id) => fixtures.groupement(id);

MembershipComplete membership(
  String associationId,
  int order, {
  String? roleTags,
}) => fixtures.membershipFixture(
  associationId: associationId,
  memberOrder: order,
  roleTags: roleTags,
);

MemberComplete member(String id, List<MembershipComplete> memberships) =>
    fixtures.memberWithMemberships(id, memberships);

void main() {
  group('phonebook/tools/function', () {
    test(
      'getMembershipForAssociation finds the membership for the mandate year',
      () {
        final asso = association('a1', 'BDE', mandateYear: 2026);
        final current = membership('a1', 0);
        final past = MembershipComplete.empty().copyWith(
          associationId: 'a1',
          mandateYear: 2025,
          memberOrder: 3,
        );
        final m = member('u1', [past, current]);

        expect(getMembershipForAssociation(m, asso), same(current));
        expect(getPosition(m, asso), 0);
      },
    );

    test('getMembershipForAssociation falls back to an empty membership', () {
      final asso = association('a2', 'BDF');
      final m = member('u1', [membership('a1', 0)]);

      final membershipResult = getMembershipForAssociation(m, asso);
      expect(membershipResult.id, '');
      expect(getPosition(m, asso), 0);
    });

    test('sortedAssociationByKind groups and sorts by groupement', () {
      final groupements = [groupement('g1'), groupement('g2')];
      final associations = [
        association('b', 'École', groupementId: 'g1'),
        association('a', 'Amicale', groupementId: 'g1'),
        association('z', 'Zorglub', groupementId: 'g2'),
      ];

      final sorted = sortedAssociationByKind(associations, groupements);

      expect(
        sorted.map((a) => a.id),
        // Groupement order first, then alphabetical order inside each.
        ['a', 'b', 'z'],
      );
    });

    test(
      'sortedAssociationByKind crashes on an unknown groupement id (! unwrap)',
      () {
        // Documented as-is: the function indexes sortedByGroupement without
        // guarding, so an association pointing to a deleted groupement
        // crashes the whole phonebook list instead of being skipped.
        final groupements = [groupement('g1')];
        final associations = [
          association('x', 'Orpheline', groupementId: 'ghost'),
        ];

        expect(
          () => sortedAssociationByKind(associations, groupements),
          throwsA(anything),
        );
      },
    );

    test('sortedAssociationByKind sorts accents case-insensitively', () {
      final groupements = [groupement('g1')];
      final associations = [
        association('1', 'école', groupementId: 'g1'),
        association('2', 'ECOLE', groupementId: 'g1'),
        association('3', 'électricité', groupementId: 'g1'),
        association('4', 'elephant', groupementId: 'g1'),
      ];

      final sorted = sortedAssociationByKind(associations, groupements);

      // ecole (x2, input order for the tie), electricite, elephant.
      expect(sorted.map((a) => a.id), ['1', '2', '3', '4']);
    });
  });

  group('associationFilteredListProvider', () {
    late ProviderContainer container;
    late List<AssociationComplete> associations;

    setUp(() {
      associations = [
        association('a', 'Amicale', groupementId: 'g1'),
        association('b', 'École', groupementId: 'g1'),
        association('c', 'Zorglub', groupementId: 'g2'),
      ];
      container = ProviderContainer(
        overrides: [
          notifierBuildOverride(
            associationListProvider,
            AsyncValue.data(associations),
          ),
          notifierBuildOverride(
            associationGroupementListProvider,
            AsyncValue.data([groupement('g1'), groupement('g2')]),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('returns all associations sorted by groupement without filters', () {
      expect(container.read(associationFilteredListProvider).map((a) => a.id), [
        'a',
        'b',
        'c',
      ]);
    });

    test('filters on the search text, ignoring accents and case', () {
      container.read(filterProvider.notifier).setFilter('Ecole');

      expect(container.read(associationFilteredListProvider).map((a) => a.id), [
        'b',
      ]);
    });

    test('restricts to the selected groupement', () {
      container
          .read(associationGroupementProvider.notifier)
          .setAssociationGroupement(groupement('g2'));

      expect(container.read(associationFilteredListProvider).map((a) => a.id), [
        'c',
      ]);
    });

    test('combines the search text and the groupement filter', () {
      container.read(filterProvider.notifier).setFilter('e');
      container
          .read(associationGroupementProvider.notifier)
          .setAssociationGroupement(groupement('g1'));

      expect(container.read(associationFilteredListProvider).map((a) => a.id), [
        'a',
        'b',
      ]);
    });
  });

  group('phonebook admin providers', () {
    CoreUser userWithGroups(List<String> groupIds) => CoreUser.empty().copyWith(
      groups: groupIds.map((id) => CoreGroupSimple(id: id, name: id)).toList(),
    );

    test('isPhonebookAdminProvider detects the admin_phonebook group', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(
            userWithGroups([fixtures.phonebookAdminGroupId]),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isPhonebookAdminProvider), isTrue);
    });

    test('hasPhonebookAdminAccessProvider also accepts a plain admin', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(userWithGroups([adminGroupId])),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isPhonebookAdminProvider), isFalse);
      expect(container.read(hasPhonebookAdminAccessProvider), isTrue);
    });

    test('hasPhonebookAdminAccessProvider is false for regular users', () {
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(CoreUser.empty())],
      );
      addTearDown(container.dispose);

      expect(container.read(hasPhonebookAdminAccessProvider), isFalse);
    });

    test('isAssociationPresidentProvider detects the president role tag', () {
      const presidentTag = 'president-tag-id';
      final me = CoreUser.empty().copyWith(id: 'me');
      final members = [
        MemberComplete.empty().copyWith(
          id: 'other',
          memberships: [membership('a1', 0)],
        ),
        MemberComplete.empty().copyWith(
          id: 'me',
          memberships: [membership('a1', 1, roleTags: presidentTag)],
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(me),
          notifierBuildOverride(associationProvider, association('a1', 'BDE')),
          notifierBuildOverride(
            associationMemberListProvider,
            AsyncValue.data(members),
          ),
          notifierBuildOverride(
            rolesTagsProvider,
            AsyncValue.data(RoleTagsReturn(tags: const [presidentTag])),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAssociationPresidentProvider), isTrue);
    });

    test('isAssociationPresidentProvider is false for other members', () {
      const presidentTag = 'president-tag-id';
      final me = CoreUser.empty().copyWith(id: 'me');
      final members = [
        MemberComplete.empty().copyWith(
          id: 'other',
          memberships: [membership('a1', 0, roleTags: presidentTag)],
        ),
      ];
      final containerWithAssociation = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(me),
          notifierBuildOverride(associationProvider, association('a1', 'BDE')),
          notifierBuildOverride(
            associationMemberListProvider,
            AsyncValue.data(members),
          ),
          notifierBuildOverride(
            rolesTagsProvider,
            AsyncValue.data(RoleTagsReturn(tags: const [presidentTag])),
          ),
        ],
      );
      addTearDown(containerWithAssociation.dispose);

      expect(
        containerWithAssociation.read(isAssociationPresidentProvider),
        isFalse,
      );
    });
  });

  group('associationMemberSortedListProvider', () {
    test('orders members by their member order for the association', () {
      final members = [
        member('second', [membership('a1', 1)]),
        member('first', [membership('a1', 0)]),
        member('outside', [
          MembershipComplete.empty().copyWith(
            associationId: 'other',
            mandateYear: 2026,
            memberOrder: -100,
          ),
        ]),
      ];
      final container = ProviderContainer(
        overrides: [
          notifierBuildOverride(
            associationMemberListProvider,
            AsyncValue.data(members),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(associationProvider.notifier)
          .setAssociation(association('a1', 'BDE'));

      expect(
        container.read(associationMemberSortedListProvider).map((m) => m.id),
        // 'outside' has no membership for this association: getPosition
        // reads the empty membership's memberOrder (0), tying it with
        // 'first'. The list is short enough for Dart's stable sort, so ties
        // keep their original relative order.
        ['first', 'outside', 'second'],
      );
    });
  });
}
