import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/admin/providers/association_membership_list_provider.dart';
import 'package:titan/admin/providers/association_membership_members_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

// Module-local name kept so a rename does not grep across 60 files;
// the behaviour is the shared whole-app MockOpenapi.
class MockRepository extends MockOpenapi {}

// build() fetches from the repository in the real notifier; these tests
// drive the CRUD arms directly, so the fake skips the network.
class _MembersNotifier extends AssociationMembershipMembersNotifier {
  @override
  AsyncValue<List<UserMembershipComplete>> build() =>
      const AsyncValue.loading();
}

class _MembershipNotifier extends AssociationMembershipListNotifier {
  @override
  AsyncValue<List<MembershipSimple>> build() => const AsyncValue.loading();
}

void main() {
  group('AssociationMembershipListNotifier CRUD', () {
    late MockRepository repo;
    late ProviderContainer container;
    late AssociationMembershipListNotifier notifier;

    final membership = MembershipSimple.empty().copyWith(
      id: 'm-1',
      name: 'BDE',
      managerGroupId: 'g-1',
    );

    setUp(() {
      repo = MockRepository();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allAssociationMembershipListProvider.overrideWith(
            _MembershipNotifier.new,
          ),
        ],
      );
      notifier = container.read(allAssociationMembershipListProvider.notifier);
      notifier.state = AsyncValue.data([membership]);
    });

    tearDown(() => container.dispose());

    test(
      'createAssociationMembership posts the name and manager group',
      () async {
        when(() => repo.membershipsPost(body: any(named: 'body')))
            .thenAnswer((_) async => repo.ok(membership));

        final ok = await notifier.createAssociationMembership(membership);

        expect(ok, isTrue);
        expect(notifier.state.value, hasLength(2));
        final captured = verify(
          () => repo.membershipsPost(body: captureAny(named: 'body')),
        ).captured.single;
        expect(captured.name, 'BDE');
        expect(captured.managerGroupId, 'g-1');
      },
    );

    test('updateAssociationMembership patches and replaces in place', () async {
      when(
        () => repo.membershipsAssociationMembershipIdPatch(
          associationMembershipId: 'm-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final renamed = membership.copyWith(name: 'BDE updated');
      final ok = await notifier.updateAssociationMembership(renamed);

      expect(ok, isTrue);
      expect(notifier.state.value!.single.name, 'BDE updated');
    });

    test('a refused update keeps the previous list', () async {
      when(
        () => repo.membershipsAssociationMembershipIdPatch(
          associationMembershipId: 'm-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.fail<void>(500));

      final ok = await notifier.updateAssociationMembership(
        membership.copyWith(name: 'nope'),
      );

      expect(ok, isFalse);
      expect(notifier.state.value!.single.name, 'BDE');
    });

    test('deleteAssociationMembership removes the entry', () async {
      when(
        () => repo.membershipsAssociationMembershipIdDelete(
          associationMembershipId: 'm-1',
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deleteAssociationMembership(membership);

      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });
  });

  group('AssociationMembershipMembersNotifier CRUD', () {
    late MockRepository repo;
    late ProviderContainer container;
    late AssociationMembershipMembersNotifier notifier;

    final member = UserMembershipComplete.empty().copyWith(
      id: 'um-1',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 6, 30),
    );

    setUp(() {
      repo = MockRepository();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          associationMembershipMembersProvider.overrideWith(
            _MembersNotifier.new,
          ),
        ],
      );
      notifier = container.read(associationMembershipMembersProvider.notifier);
      notifier.state = AsyncValue.data([member]);
    });

    tearDown(() => container.dispose());

    test('loadAssociationMembershipMembers formats the date filters', () async {
      when(
        () => repo.membershipsAssociationMembershipIdMembersGet(
          associationMembershipId: 'am-1',
          minimalStartDate: '2026-01-01',
          minimalEndDate: '2026-02-01',
          maximalStartDate: '2026-03-01',
          maximalEndDate: '2026-04-01',
        ),
      ).thenAnswer((_) async => repo.okList<UserMembershipComplete>());

      final result = await notifier.loadAssociationMembershipMembers(
        'am-1',
        minimalStartDate: DateTime(2026, 1, 1),
        minimalEndDate: DateTime(2026, 2, 1),
        maximalStartDate: DateTime(2026, 3, 1),
        maximalEndDate: DateTime(2026, 4, 1),
      );

      expect(result, isA<AsyncData<List<UserMembershipComplete>>>());
    });

    test('addMember posts the membership body', () async {
      when(
        () => repo.membershipsUsersUserIdPost(
          userId: 'u-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.ok(member));

      final ok = await notifier.addMember(
        UserMembershipComplete.empty().copyWith(
          id: 'am-1',
          associationMembershipId: 'am-1',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
        CoreUserSimple.empty().copyWith(id: 'u-1'),
      );

      expect(ok, isTrue);
      final captured = verify(
        () => repo.membershipsUsersUserIdPost(
          userId: any(named: 'userId'),
          body: captureAny(named: 'body'),
        ),
      ).captured.single;
      expect(captured.associationMembershipId, 'am-1');
      expect(captured.endDate, DateTime(2026, 12, 31));
    });

    test('updateMember patches the dates and rewrites the row', () async {
      when(
        () => repo.membershipsUsersMembershipIdPatch(
          membershipId: 'um-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final updated = member.copyWith(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final ok = await notifier.updateMember(updated);

      expect(ok, isTrue);
      expect(notifier.state.value!.single.startDate, DateTime(2026, 2, 1));
      expect(notifier.state.value!.single.endDate, DateTime(2026, 7, 31));
    });

    test('a refused member patch keeps the previous row', () async {
      when(
        () => repo.membershipsUsersMembershipIdPatch(
          membershipId: 'um-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.fail<void>(400));

      final ok = await notifier.updateMember(member);

      expect(ok, isFalse);
      expect(notifier.state.value!.single.startDate, DateTime(2026, 1, 1));
    });

    test('deleteMember removes the member', () async {
      when(() => repo.membershipsUsersMembershipIdDelete(membershipId: 'um-1'))
          .thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deleteMember(member);

      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });
  });
}
