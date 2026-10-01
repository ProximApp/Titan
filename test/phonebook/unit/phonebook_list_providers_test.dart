import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/phonebook/providers/association_list_provider.dart';
import 'package:titan/phonebook/providers/association_member_list_provider.dart';
import 'package:titan/phonebook/providers/association_provider.dart';
import 'package:titan/phonebook/providers/roles_tags_provider.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/repository/repository.dart';

class MockPhonebookRepository extends Mock implements Openapi {}

AssociationComplete association(String id, String name) =>
    AssociationComplete.empty().copyWith(id: id, name: name);

MemberComplete member(String id, List<MembershipComplete> memberships) =>
    MemberComplete.empty().copyWith(id: id, memberships: memberships);

MembershipComplete membership(String associationId, int year, int order) =>
    MembershipComplete.empty().copyWith(
      associationId: associationId,
      mandateYear: year,
      memberOrder: order,
    );

void main() {
  group('Phonebook list providers (ListNotifierAPI)', () {
    late MockPhonebookRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPhonebookRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('AssociationListNotifier', () {
      test('build fetches all associations right away', () async {
        final all = [association('1', 'BDE'), association('2', 'BDF')];
        when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), all),
        );

        container.read(associationListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(associationListProvider).value, all);
      });

      test('build flags the error when the fetch fails', () async {
        when(
          () => mockRepository.phonebookAssociationsGet(),
        ).thenThrow(Exception('network down'));

        container.read(associationListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(associationListProvider),
          isA<AsyncError<List<AssociationComplete>>>(),
        );
      });

      test('updateAssociation replaces the association in the list', () async {
        final bde = association('1', 'BDE');
        when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [bde]),
        );
        final notifier = container.read(associationListProvider.notifier);
        await notifier.loadAssociations();

        when(
          () => mockRepository.phonebookAssociationsAssociationIdPatch(
            associationId: any(named: 'associationId'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );

        final renamed = bde.copyWith(name: 'BDE 2026');
        final result = await notifier.updateAssociation(renamed);

        expect(result, isTrue);
        expect(container.read(associationListProvider).value, [renamed]);
      });

      test(
        'updateAssociation keeps the previous list when the patch fails',
        () async {
          final bde = association('1', 'BDE');
          when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), [bde]),
          );
          final notifier = container.read(associationListProvider.notifier);
          await notifier.loadAssociations();

          when(
            () => mockRepository.phonebookAssociationsAssociationIdPatch(
              associationId: any(named: 'associationId'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<void>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );

          final result = await notifier.updateAssociation(
            bde.copyWith(name: 'X'),
          );

          expect(result, isFalse);
          expect(container.read(associationListProvider).value, [bde]);
        },
      );

      test('deleteAssociation removes it from the list', () async {
        final bde = association('1', 'BDE');
        final bdf = association('2', 'BDF');
        when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [bde, bdf]),
        );
        final notifier = container.read(associationListProvider.notifier);
        await notifier.loadAssociations();

        when(
          () => mockRepository.phonebookAssociationsAssociationIdDelete(
            associationId: any(named: 'associationId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );

        final result = await notifier.deleteAssociation(bde);

        expect(result, isTrue);
        expect(container.read(associationListProvider).value, [bdf]);
      });

      test('deactivateAssociation flags it deactivated in the list', () async {
        final bde = association('1', 'BDE');
        when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [bde]),
        );
        final notifier = container.read(associationListProvider.notifier);
        await notifier.loadAssociations();

        when(
          () =>
              mockRepository.phonebookAssociationsAssociationIdDeactivatePatch(
                associationId: any(named: 'associationId'),
              ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );

        final result = await notifier.deactivateAssociation(bde);

        expect(result, isTrue);
        expect(container.read(associationListProvider).value, [
          bde.copyWith(deactivated: true),
        ]);
      });

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        // The first stub settles build()'s fire-and-forget load; rethrowing
        // from it would leave an unhandled async error in the zone.
        when(() => mockRepository.phonebookAssociationsGet()).thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 200),
            <AssociationComplete>[],
          ),
        );
        final notifier = container.read(associationListProvider.notifier);
        await notifier.loadAssociations();

        when(() => mockRepository.phonebookAssociationsGet()).thenThrow(error);

        await expectLater(notifier.loadAssociations(), throwsA(same(error)));
      });
    });

    group('RolesTagsNotifier', () {
      test('build fetches the role tags right away', () async {
        final tags = RoleTagsReturn(tags: const ['President', 'Treasurer']);
        when(() => mockRepository.phonebookRoletagsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), tags),
        );

        container.read(rolesTagsProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(rolesTagsProvider).value, tags);
      });

      test('loadRolesTags flags the error when the fetch fails', () async {
        // A synchronous throw settles before build() returns its loading
        // value, which overwrites the error state; load through the notifier
        // instead to observe the error contract.
        when(() => mockRepository.phonebookRoletagsGet()).thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 200),
            RoleTagsReturn.empty(),
          ),
        );
        final notifier = container.read(rolesTagsProvider.notifier);
        await notifier.loadRolesTags();

        when(
          () => mockRepository.phonebookRoletagsGet(),
        ).thenThrow(Exception('network down'));

        final result = await notifier.loadRolesTags();

        expect(result, isA<AsyncError<RoleTagsReturn>>());
        expect(
          container.read(rolesTagsProvider),
          isA<AsyncError<RoleTagsReturn>>(),
        );
      });
    });

    group('AssociationMemberListNotifier', () {
      test('rebuilds when the selected association changes', () async {
        final bde = AssociationComplete.empty().copyWith(
          id: 'asso-1',
          mandateYear: 2026,
        );
        when(
          () => mockRepository
              .phonebookAssociationsAssociationIdMembersMandateYearGet(
                associationId: any(named: 'associationId'),
                mandateYear: any(named: 'mandateYear'),
              ),
        ).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <MemberComplete>[]),
        );

        // build() watches the selected association and loads its members for
        // the association's mandate year.
        container.read(associationProvider.notifier).setAssociation(bde);
        container.read(associationMemberListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockRepository
              .phonebookAssociationsAssociationIdMembersMandateYearGet(
                associationId: 'asso-1',
                mandateYear: 2026,
              ),
        ).called(1);
      });

      test('loadMembers exposes the association members', () async {
        final members = [
          member('1', [membership('asso-1', 2026, 0)]),
          member('2', [membership('asso-1', 2026, 1)]),
        ];
        when(
          () => mockRepository
              .phonebookAssociationsAssociationIdMembersMandateYearGet(
                associationId: any(named: 'associationId'),
                mandateYear: any(named: 'mandateYear'),
              ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), members),
        );

        final result = await container
            .read(associationMemberListProvider.notifier)
            .loadMembers('asso-1', 2026);

        expect(result.value, members);
      });

      test(
        'addMember appends the member when the membership is created',
        () async {
          final created = MembershipComplete.empty().copyWith(
            id: 'membership-1',
            associationId: 'asso-1',
          );
          when(
            () => mockRepository
                .phonebookAssociationsAssociationIdMembersMandateYearGet(
                  associationId: any(named: 'associationId'),
                  mandateYear: any(named: 'mandateYear'),
                ),
          ).thenAnswer(
            (_) async => chopper.Response(
              http.Response('body', 200),
              <MemberComplete>[],
            ),
          );
          when(
            () => mockRepository.phonebookAssociationsMembershipsPost(
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 201), created),
          );
          final notifier = container.read(
            associationMemberListProvider.notifier,
          );
          await notifier.loadMembers('asso-1', 2026);
          expect(notifier.state.value, isEmpty);

          final newMember = member('9', []);
          final result = await notifier.addMember(
            newMember,
            AppModulesPhonebookSchemasPhonebookMembershipBase.empty(),
          );

          expect(result, isTrue);
          expect(notifier.state.value, [newMember]);
        },
      );

      test(
        'addMember fails without touching the list when the endpoint rejects',
        () async {
          when(
            () => mockRepository
                .phonebookAssociationsAssociationIdMembersMandateYearGet(
                  associationId: any(named: 'associationId'),
                  mandateYear: any(named: 'mandateYear'),
                ),
          ).thenAnswer(
            (_) async => chopper.Response(
              http.Response('body', 200),
              <MemberComplete>[],
            ),
          );
          when(
            () => mockRepository.phonebookAssociationsMembershipsPost(
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => chopper.Response<MembershipComplete>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );
          final notifier = container.read(
            associationMemberListProvider.notifier,
          );
          await notifier.loadMembers('asso-1', 2026);

          final result = await notifier.addMember(
            member('9', []),
            AppModulesPhonebookSchemasPhonebookMembershipBase.empty(),
          );

          expect(result, isFalse);
          expect(notifier.state.value, isEmpty);
        },
      );

      test('updateMember replaces the member in the list', () async {
        final president = member('1', [membership('asso-1', 2026, 0)]);
        when(
          () => mockRepository
              .phonebookAssociationsAssociationIdMembersMandateYearGet(
                associationId: any(named: 'associationId'),
                mandateYear: any(named: 'mandateYear'),
              ),
        ).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), [president]),
        );
        final notifier = container.read(associationMemberListProvider.notifier);
        await notifier.loadMembers('asso-1', 2026);

        when(
          () =>
              mockRepository.phonebookAssociationsMembershipsMembershipIdPatch(
                membershipId: any(named: 'membershipId'),
                body: any(named: 'body'),
              ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );

        final renamed = president.copyWith(name: 'Maxime');
        final result = await notifier.updateMember(
          renamed,
          MembershipComplete.empty().copyWith(id: 'm-1'),
        );

        expect(result, isTrue);
        expect(notifier.state.value, [renamed]);
      });

      test('deleteMember removes the member from the list', () async {
        final kept = member('1', [membership('asso-1', 2026, 0)]);
        final removed = member('2', [membership('asso-1', 2026, 1)]);
        when(
          () => mockRepository
              .phonebookAssociationsAssociationIdMembersMandateYearGet(
                associationId: any(named: 'associationId'),
                mandateYear: any(named: 'mandateYear'),
              ),
        ).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), [kept, removed]),
        );
        final notifier = container.read(associationMemberListProvider.notifier);
        await notifier.loadMembers('asso-1', 2026);

        when(
          () =>
              mockRepository.phonebookAssociationsMembershipsMembershipIdDelete(
                membershipId: any(named: 'membershipId'),
              ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );

        final result = await notifier.deleteMember(
          removed,
          MembershipComplete.empty().copyWith(id: 'm-2'),
        );

        expect(result, isTrue);
        expect(notifier.state.value, [kept]);
      });

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(
          () => mockRepository
              .phonebookAssociationsAssociationIdMembersMandateYearGet(
                associationId: any(named: 'associationId'),
                mandateYear: any(named: 'mandateYear'),
              ),
        ).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <MemberComplete>[]),
        );
        final notifier = container.read(associationMemberListProvider.notifier);
        await notifier.loadMembers('asso-1', 2026);

        when(
          () => mockRepository
              .phonebookAssociationsAssociationIdMembersMandateYearGet(
                associationId: any(named: 'associationId'),
                mandateYear: any(named: 'mandateYear'),
              ),
        ).thenThrow(error);
        await expectLater(
          notifier.loadMembers('asso-1', 2026),
          throwsA(same(error)),
        );
      });
    });
  });
}
