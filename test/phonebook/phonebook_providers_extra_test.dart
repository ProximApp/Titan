import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
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
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';

class MockRepository extends Mock implements Openapi {}

class FakeAssociationListNotifier extends AssociationListNotifier {
  FakeAssociationListNotifier(this.associations);
  final List<AssociationComplete> associations;

  @override
  AsyncValue<List<AssociationComplete>> build() => AsyncValue.data(associations);
}

class FakeGroupementListNotifier extends AssociationGroupementListNotifier {
  FakeGroupementListNotifier(this.groupements);
  final List<AssociationGroupement> groupements;

  @override
  AsyncValue<List<AssociationGroupement>> build() =>
      AsyncValue.data(groupements);
}

class FakeGroupementNotifier extends AssociationGroupementNotifier {
  FakeGroupementNotifier(this.groupement);
  final AssociationGroupement groupement;

  @override
  AssociationGroupement build() => groupement;
}

class FakeMembersNotifier extends AssociationMemberListNotifier {
  FakeMembersNotifier(this.members);
  final List<MemberComplete> members;

  @override
  AsyncValue<List<MemberComplete>> build() => AsyncValue.data(members);
}

class _LoadingAssociationListNotifier extends AssociationListNotifier {
  @override
  AsyncValue<List<AssociationComplete>> build() => const AsyncValue.loading();
}

class _LoadingGroupementListNotifier extends AssociationGroupementListNotifier {
  @override
  AsyncValue<List<AssociationGroupement>> build() =>
      const AsyncValue.loading();
}

class _LoadingMembersListNotifier extends AssociationMemberListNotifier {
  @override
  AsyncValue<List<MemberComplete>> build() => const AsyncValue.loading();
}

class FakeRolesTagsNotifier extends RolesTagsNotifier {
  FakeRolesTagsNotifier(this.tags);
  final List<String> tags;

  @override
  AsyncValue<RoleTagsReturn> build() => AsyncValue.data(RoleTagsReturn(tags: tags));
}

MemberComplete memberWithMembership(
  String id,
  String associationId, {
  int mandateYear = 2024,
  int order = 0,
  String? roleTags,
}) {
  return MemberComplete.empty().copyWith(
    id: id,
    memberships: [
      MembershipComplete.empty().copyWith(
        userId: id,
        associationId: associationId,
        mandateYear: mandateYear,
        memberOrder: order,
        roleTags: roleTags,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    // build() fires loadAssociations() in a microtask: every CRUD test needs
    // the listing call stubbed so the state settles on data. Baseline is an
    // empty list; tests that need the association pre-loaded re-stub below.
    when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <AssociationComplete>[]),
    );
  });

  group('phonebook tools functions', () {
    test('getMembershipForAssociation matches id and mandate year', () {
      final association = AssociationComplete.empty().copyWith(
        id: 'a-1',
        mandateYear: 2024,
      );
      final matching = MembershipComplete.empty().copyWith(
        associationId: 'a-1',
        mandateYear: 2024,
        memberOrder: 2,
      );
      final member = MemberComplete.empty().copyWith(
        memberships: [
          MembershipComplete.empty().copyWith(associationId: 'a-1', mandateYear: 2023),
          matching,
        ],
      );

      expect(getMembershipForAssociation(member, association), matching);
      expect(getPosition(member, association), 2);
    });

    test('getMembershipForAssociation falls back to an empty membership', () {
      final association = AssociationComplete.empty().copyWith(id: 'a-1');
      final member = MemberComplete.empty();

      expect(
        getMembershipForAssociation(member, association),
        MembershipComplete.empty(),
      );
      expect(getPosition(member, association), 0);
    });

    test('sortedMembers sorts by member order', () {
      final association = AssociationComplete.empty().copyWith(
        id: 'a-1',
        mandateYear: 2024,
      );
      final members = [
        memberWithMembership('m-3', 'a-1', order: 2),
        memberWithMembership('m-1', 'a-1', order: 0),
        memberWithMembership('m-2', 'a-1', order: 1),
      ];

      final sorted = sortedMembers(members, association);

      expect(sorted.map((m) => m.id), ['m-1', 'm-2', 'm-3']);
    });

    test('sortedAssociationByKind groups by groupement then sorts by name', () {
      final groupements = [
        AssociationGroupement.empty().copyWith(id: 'g-1', name: 'Culture'),
        AssociationGroupement.empty().copyWith(id: 'g-2', name: 'Sport'),
      ];
      final associations = [
        AssociationComplete.empty().copyWith(id: 'a-1', groupementId: 'g-2', name: 'Zoo'),
        AssociationComplete.empty().copyWith(id: 'a-2', groupementId: 'g-1', name: 'Échecs'),
        AssociationComplete.empty().copyWith(id: 'a-3', groupementId: 'g-1', name: 'Arts'),
      ];

      final sorted = sortedAssociationByKind(associations, groupements);

      expect(sorted.map((a) => a.id), ['a-3', 'a-2', 'a-1']);
    });
  });

  group('associationMemberSortedListProvider', () {
    test('sorts the members of the selected association', () {
      final association = AssociationComplete.empty().copyWith(
        id: 'a-1',
        mandateYear: 2024,
      );
      final container = ProviderContainer(
        overrides: [
          associationProvider.overrideWith(
            () => FakeAssociationNotifier(association),
          ),
          associationMemberListProvider.overrideWith(
            () => FakeMembersNotifier([
              memberWithMembership('m-2', 'a-1', order: 1),
              memberWithMembership('m-1', 'a-1', order: 0),
            ]),
          ),
        ],
      );

      final sorted = container.read(associationMemberSortedListProvider);

      expect(sorted.map((m) => m.id), ['m-1', 'm-2']);

      container.dispose();
    });

    test('is empty while the members are loading', () {
      final container = ProviderContainer(
        overrides: [
          associationProvider.overrideWith(
            () => FakeAssociationNotifier(AssociationComplete.empty()),
          ),
          associationMemberListProvider.overrideWith(
            _LoadingMembersListNotifier.new,
          ),
        ],
      );

      expect(container.read(associationMemberSortedListProvider), isEmpty);

      container.dispose();
    });
  });

  group('associationFilteredListProvider', () {
    final groupements = [
      AssociationGroupement.empty().copyWith(id: 'g-1', name: 'Culture'),
      AssociationGroupement.empty().copyWith(id: 'g-2', name: 'Sport'),
    ];
    final associations = [
      AssociationComplete.empty().copyWith(id: 'a-1', groupementId: 'g-1', name: 'Échecs'),
      AssociationComplete.empty().copyWith(id: 'a-2', groupementId: 'g-1', name: 'Arts'),
      AssociationComplete.empty().copyWith(id: 'a-3', groupementId: 'g-2', name: 'Écurie'),
    ];

    test('filters by name ignoring accents and case', () {
      final container = ProviderContainer(
        overrides: [
          associationListProvider.overrideWith(
            () => FakeAssociationListNotifier(associations),
          ),
          associationGroupementListProvider.overrideWith(
            () => FakeGroupementListNotifier(groupements),
          ),
          associationGroupementProvider.overrideWith(
            () => FakeGroupementNotifier(AssociationGroupement.empty()),
          ),
          filterProvider.overrideWith(() => FakeFilterNotifier('eche')),
        ],
      );

      final filtered = container.read(associationFilteredListProvider);

      expect(filtered, hasLength(1));
      expect(filtered.single.id, 'a-1');

      container.dispose();
    });

    test('keeps every association with an empty filter and no groupement', () {
      final container = ProviderContainer(
        overrides: [
          associationListProvider.overrideWith(
            () => FakeAssociationListNotifier(associations),
          ),
          associationGroupementListProvider.overrideWith(
            () => FakeGroupementListNotifier(groupements),
          ),
          associationGroupementProvider.overrideWith(
            () => FakeGroupementNotifier(AssociationGroupement.empty()),
          ),
          filterProvider.overrideWith(() => FakeFilterNotifier('')),
        ],
      );

      final filtered = container.read(associationFilteredListProvider);

      expect(filtered, hasLength(3));
      // Groupement g-1's associations come first, sorted by name (Arts, Échecs).
      expect(filtered.map((a) => a.id), ['a-2', 'a-1', 'a-3']);

      container.dispose();
    });

    test('restricts to the selected groupement', () {
      final container = ProviderContainer(
        overrides: [
          associationListProvider.overrideWith(
            () => FakeAssociationListNotifier(associations),
          ),
          associationGroupementListProvider.overrideWith(
            () => FakeGroupementListNotifier(groupements),
          ),
          associationGroupementProvider.overrideWith(
            () => FakeGroupementNotifier(
              AssociationGroupement.empty().copyWith(id: 'g-1'),
            ),
          ),
          filterProvider.overrideWith(() => FakeFilterNotifier('')),
        ],
      );

      final filtered = container.read(associationFilteredListProvider);

      expect(filtered.map((a) => a.id), ['a-2', 'a-1']);

      container.dispose();
    });

    test('is empty while the associations are loading', () {
      final container = ProviderContainer(
        overrides: [
          associationListProvider.overrideWith(_LoadingAssociationListNotifier.new),
          associationGroupementListProvider.overrideWith(
            _LoadingGroupementListNotifier.new,
          ),
          filterProvider.overrideWith(() => FakeFilterNotifier('')),
        ],
      );

      expect(container.read(associationFilteredListProvider), isEmpty);

      container.dispose();
    });
  });

  group('AssociationListNotifier', () {
    final association = AssociationComplete.empty().copyWith(
      id: 'a-1',
      name: 'Club',
      description: 'A club',
      mandateYear: 2024,
    );

    test('loadAssociations loads the associations', () async {
      when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), [association]),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(associationListProvider.notifier);
      final result = await notifier.loadAssociations();

      expect(result.value, [association]);

      container.dispose();
    });

    test('createAssociation appends the created association', () async {
      final base =
          AppModulesPhonebookSchemasPhonebookAssociationBase.empty();
      when(() => mockRepository.phonebookAssociationsPost(body: base)).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), association),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(associationListProvider.notifier);
      await notifier.loadAssociations();
      final ok = await notifier.createAssociation(base);

      expect(ok, isTrue);
      expect(container.read(associationListProvider).value, [association]);

      container.dispose();
    });

    test('deleteAssociation removes the association', () async {
      when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), [association]),
      );
      when(
        () => mockRepository.phonebookAssociationsAssociationIdDelete(
          associationId: 'a-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(associationListProvider.notifier);
      await notifier.loadAssociations();
      final ok = await notifier.deleteAssociation(association);

      expect(ok, isTrue);
      expect(container.read(associationListProvider).value, isEmpty);

      container.dispose();
    });

    test('deactivateAssociation flags the association as deactivated', () async {
      when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), [association]),
      );
      when(
        () => mockRepository.phonebookAssociationsAssociationIdDeactivatePatch(
          associationId: 'a-1',
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );

      final notifier = container.read(associationListProvider.notifier);
      await notifier.loadAssociations();
      final ok = await notifier.deactivateAssociation(association);

      expect(ok, isTrue);
      expect(
        container.read(associationListProvider).value!.first.deactivated,
        isTrue,
      );

      container.dispose();
    });
  });

  group('isPhonebookAdminProvider', () {
    test('is true when the user is in the phonebook admin group', () {
      final user = CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: 'd3f91313-d7e5-49c6-b01f-c19932a7e09b',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(user)],
      );

      expect(container.read(isPhonebookAdminProvider), isTrue);
      expect(container.read(hasPhonebookAdminAccessProvider), isTrue);

      container.dispose();
    });

    test('hasPhonebookAdminAccessProvider falls back to the global admin', () {
      final user = CoreUser.empty().copyWith(
        groups: [
          CoreGroupSimple.empty().copyWith(
            id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(user)],
      );

      expect(container.read(isPhonebookAdminProvider), isFalse);
      expect(container.read(hasPhonebookAdminAccessProvider), isTrue);

      container.dispose();
    });

    test('is false for a regular user', () {
      final container = ProviderContainer(
        overrides: [userProvider.overrideWithValue(CoreUser.empty())],
      );

      expect(container.read(isPhonebookAdminProvider), isFalse);
      expect(container.read(hasPhonebookAdminAccessProvider), isFalse);

      container.dispose();
    });
  });

  group('isAssociationPresidentProvider', () {
    final association = AssociationComplete.empty().copyWith(
      id: 'a-1',
      mandateYear: 2024,
    );

    test('is true for the member holding the president role tag', () {
      final user = CoreUser.empty().copyWith(id: 'u-1');
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(user),
          associationProvider.overrideWith(
            () => FakeAssociationNotifier(association),
          ),
          rolesTagsProvider.overrideWith(
            () => FakeRolesTagsNotifier(['president']),
          ),
          associationMemberListProvider.overrideWith(
            () => FakeMembersNotifier([
              memberWithMembership(
                'u-1',
                'a-1',
                mandateYear: 2024,
                roleTags: 'president',
              ),
            ]),
          ),
        ],
      );

      expect(container.read(isAssociationPresidentProvider), isTrue);

      container.dispose();
    });

    test('is false when the user is not a member', () {
      final user = CoreUser.empty().copyWith(id: 'u-other');
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(user),
          associationProvider.overrideWith(
            () => FakeAssociationNotifier(association),
          ),
          rolesTagsProvider.overrideWith(
            () => FakeRolesTagsNotifier(['president']),
          ),
          associationMemberListProvider.overrideWith(
            () => FakeMembersNotifier([
              memberWithMembership(
                'u-1',
                'a-1',
                mandateYear: 2024,
                roleTags: 'president',
              ),
            ]),
          ),
        ],
      );

      expect(container.read(isAssociationPresidentProvider), isFalse);

      container.dispose();
    });

    test('is false when the member has no matching role tag', () {
      final user = CoreUser.empty().copyWith(id: 'u-1');
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(user),
          associationProvider.overrideWith(
            () => FakeAssociationNotifier(association),
          ),
          rolesTagsProvider.overrideWith(() => FakeRolesTagsNotifier(['treasurer'])),
          associationMemberListProvider.overrideWith(
            () => FakeMembersNotifier([
              memberWithMembership(
                'u-1',
                'a-1',
                mandateYear: 2024,
                roleTags: 'president',
              ),
            ]),
          ),
        ],
      );

      expect(container.read(isAssociationPresidentProvider), isFalse);

      container.dispose();
    });
  });
}

class FakeAssociationNotifier extends AssociationNotifier {
  FakeAssociationNotifier(this.association);
  final AssociationComplete association;

  @override
  AssociationComplete build() => association;
}

class FakeFilterNotifier extends FilterNotifier {
  FakeFilterNotifier(this.filter);
  final String filter;

  @override
  String build() => filter;
}
