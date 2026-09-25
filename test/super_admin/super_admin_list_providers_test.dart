import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/super_admin/providers/account_types_list_provider.dart';
import 'package:titan/super_admin/providers/permission_name_list_provider.dart';
import 'package:titan/super_admin/providers/permissions_list_provider.dart';
import 'package:titan/super_admin/providers/school_list_provider.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/repository/repository.dart';

class MockSuperAdminRepository extends Mock implements Openapi {}

class FakeIsLoggedInNotifier extends IsLoggedInProvider {
  FakeIsLoggedInNotifier(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

CoreSchool school(String id, String name) =>
    CoreSchool.empty().copyWith(id: id, name: name);

CorePermission permission(
  String name, {
  List<String> groups = const [],
  List<enums.AccountType> types = const [],
}) => CorePermission.empty().copyWith(
  permissionName: name,
  groups: groups,
  accountTypes: types,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Super admin list providers (ListNotifierAPI)', () {
    late MockSuperAdminRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      // PermissionsNotifier reads the real isLoggedInProvider, which touches
      // IsCachingProvider and its SharedPreferences-backed cache.
      SharedPreferences.setMockInitialValues({});
      mockRepository = MockSuperAdminRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() => container.dispose());

    group('SchoolListNotifier', () {
      test('build fetches the schools right away', () async {
        final all = [school('1', 'EFREI')];
        when(() => mockRepository.schoolsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), all),
        );

        container.read(allSchoolListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(allSchoolListProvider).value, all);
      });

      test('createSchool appends the created school', () async {
        final created = school('1', 'EFREI');
        when(() => mockRepository.schoolsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <CoreSchool>[]),
        );
        when(
          () => mockRepository.schoolsPost(body: any(named: 'body')),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 201), created),
        );
        final notifier = container.read(allSchoolListProvider.notifier);
        await notifier.loadSchools();

        final result = await notifier.createSchool(created);

        expect(result, isTrue);
        expect(container.read(allSchoolListProvider).value, [created]);
      });

      test('createSchool fails when the backend rejects it', () async {
        when(() => mockRepository.schoolsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <CoreSchool>[]),
        );
        when(
          () => mockRepository.schoolsPost(body: any(named: 'body')),
        ).thenAnswer(
          (_) async => chopper.Response<CoreSchool>(
            http.Response('invalid', 400),
            null,
            error: 'invalid',
          ),
        );
        final notifier = container.read(allSchoolListProvider.notifier);
        await notifier.loadSchools();

        final result = await notifier.createSchool(school('1', 'EFREI'));

        expect(result, isFalse);
        expect(container.read(allSchoolListProvider).value, isEmpty);
      });

      test('updateSchool replaces the school in the list', () async {
        final efrei = school('1', 'EFREI');
        when(() => mockRepository.schoolsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [efrei]),
        );
        when(
          () => mockRepository.schoolsSchoolIdPatch(
            schoolId: any(named: 'schoolId'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );
        final notifier = container.read(allSchoolListProvider.notifier);
        await notifier.loadSchools();

        final renamed = efrei.copyWith(name: 'EFREI Paris');
        final result = await notifier.updateSchool(renamed);

        expect(result, isTrue);
        expect(container.read(allSchoolListProvider).value, [renamed]);
      });

      test('deleteSchool removes it from the list', () async {
        final efrei = school('1', 'EFREI');
        final epsi = school('2', 'EPSI');
        when(() => mockRepository.schoolsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), [efrei, epsi]),
        );
        when(
          () => mockRepository.schoolsSchoolIdDelete(
            schoolId: any(named: 'schoolId'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response<void>(http.Response('body', 200), null),
        );
        final notifier = container.read(allSchoolListProvider.notifier);
        await notifier.loadSchools();

        final result = await notifier.deleteSchool(efrei);

        expect(result, isTrue);
        expect(container.read(allSchoolListProvider).value, [epsi]);
      });

      test(
        'setSchool replaces the school in place, ignoring unknown ids',
        () async {
          final efrei = school('1', 'EFREI');
          final epsi = school('2', 'EPSI');
          when(() => mockRepository.schoolsGet()).thenAnswer(
            (_) async =>
                chopper.Response(http.Response('body', 200), [efrei, epsi]),
          );
          final notifier = container.read(allSchoolListProvider.notifier);
          // setSchool itself is local-only, but the list needs to be loaded
          // first for the replacement to have anything to act on.
          await notifier.loadSchools();

          notifier.setSchool(efrei.copyWith(name: 'EFREI Paris'));

          expect(
            container.read(allSchoolListProvider).value!.map((s) => s.name),
            ['EFREI Paris', 'EPSI'],
          );

          // Unknown id: the indexWhere guard leaves the list untouched.
          notifier.setSchool(school('ghost', 'Ghost'));
          expect(
            container.read(allSchoolListProvider).value!.map((s) => s.name),
            ['EFREI Paris', 'EPSI'],
          );
        },
      );

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(() => mockRepository.schoolsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <CoreSchool>[]),
        );
        final notifier = container.read(allSchoolListProvider.notifier);
        await notifier.loadSchools();

        when(() => mockRepository.schoolsGet()).thenThrow(error);

        await expectLater(notifier.loadSchools(), throwsA(same(error)));
      });
    });

    group('AccountTypesNotifier', () {
      test('build fetches the account types right away', () async {
        when(() => mockRepository.usersAccountTypesGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <String>['student']),
        );

        container.read(allAccountTypesListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(allAccountTypesListProvider).value, ['student']);
      });
    });

    group('PermissionsNamesListNotifier', () {
      test('build skips the fetch when not logged in', () async {
        final loggedOutContainer = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(mockRepository),
            isLoggedInProvider.overrideWith(
              () => FakeIsLoggedInNotifier(false),
            ),
          ],
        );
        addTearDown(loggedOutContainer.dispose);

        loggedOutContainer.read(permissionsNamesListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => mockRepository.permissionsListGet());
        expect(
          loggedOutContainer.read(permissionsNamesListProvider),
          isA<AsyncLoading<List<String>>>(),
        );
      });

      test('build fetches the permission names when logged in', () async {
        final loggedInContainer = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(mockRepository),
            isLoggedInProvider.overrideWith(() => FakeIsLoggedInNotifier(true)),
            tokenProvider.overrideWithValue('token'),
          ],
        );
        addTearDown(loggedInContainer.dispose);
        when(() => mockRepository.permissionsListGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), <String>[
            'feed.write',
            'feed.read',
          ]),
        );

        loggedInContainer.read(permissionsNamesListProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        expect(loggedInContainer.read(permissionsNamesListProvider).value, [
          'feed.write',
          'feed.read',
        ]);
      });
    });

    group('PermissionsNotifier', () {
      test('addGroupPermission replaces the permission for its name', () async {
        final feed = permission(
          'feed.write',
          types: [enums.AccountType.student],
        );
        when(() => mockRepository.permissionsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [feed]),
        );
        when(
          () => mockRepository.permissionsPost(body: any(named: 'body')),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 201), feed),
        );
        final notifier = container.read(permissionsProvider.notifier);
        await notifier.loadPermissions();

        final updated = feed.copyWith(
          accountTypes: [enums.AccountType.student, enums.AccountType.staff],
        );
        final result = await notifier.addAccountTypePermission(
          updated,
          CoreAccountTypePermission.empty(),
        );

        expect(result, isTrue);
        expect(container.read(permissionsProvider).value, [updated]);
      });

      test(
        'addGroupPermission keeps the previous permission when the endpoint fails',
        () async {
          final feed = permission('feed.write');
          when(() => mockRepository.permissionsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), [feed]),
          );
          when(
            () => mockRepository.permissionsPost(body: any(named: 'body')),
          ).thenAnswer(
            (_) async => chopper.Response<CorePermission>(
              http.Response('invalid', 400),
              null,
              error: 'invalid',
            ),
          );
          final notifier = container.read(permissionsProvider.notifier);
          await notifier.loadPermissions();

          final result = await notifier.addGroupPermission(
            feed.copyWith(groups: ['group-1']),
            CoreGroupPermission.empty(),
          );

          expect(result, isFalse);
          expect(container.read(permissionsProvider).value, [feed]);
        },
      );

      test(
        'deleteGroupPermission replaces the permission through the same update',
        () async {
          final feed = permission('feed.write', groups: ['group-1']);
          when(() => mockRepository.permissionsGet()).thenAnswer(
            (_) async => chopper.Response(http.Response('body', 200), [feed]),
          );
          when(
            () => mockRepository.permissionsDelete(body: any(named: 'body')),
          ).thenAnswer(
            (_) async =>
                chopper.Response<void>(http.Response('body', 200), null),
          );
          final notifier = container.read(permissionsProvider.notifier);
          await notifier.loadPermissions();

          final updated = feed.copyWith(groups: []);
          final result = await notifier.deleteGroupPermission(
            updated,
            CoreGroupPermission.empty(),
          );

          expect(result, isTrue);
          // deleteGroupPermission is an update: it swaps the entry for the
          // permission passed in, here the emptied one.
          expect(container.read(permissionsProvider).value, [updated]);
        },
      );

      test('rethrows AppException.tokenExpire', () async {
        final error = AppException(ErrorType.tokenExpire, 'expired');
        when(() => mockRepository.permissionsGet()).thenAnswer(
          (_) async =>
              chopper.Response(http.Response('body', 200), <CorePermission>[]),
        );
        final notifier = container.read(permissionsProvider.notifier);
        await notifier.loadPermissions();

        when(() => mockRepository.permissionsGet()).thenThrow(error);

        await expectLater(notifier.loadPermissions(), throwsA(same(error)));
      });
    });

    group('permission derived providers', () {
      test('mappedPermissionsProvider indexes permissions by name', () async {
        final feed = permission('feed.write');
        when(() => mockRepository.permissionsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [feed]),
        );
        container.read(permissionsProvider.notifier);
        await Future<void>.delayed(Duration.zero);
        await container.read(permissionsProvider.notifier).loadPermissions();

        expect(container.read(mappedPermissionsProvider), {'feed.write': feed});
      });

      test('moduleGroupedPermissionsProvider groups names by module', () async {
        when(() => mockRepository.permissionsListGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [
            'feed.write',
            'feed.read',
            'ticket',
          ]),
        );
        final loggedInContainer = ProviderContainer(
          overrides: [
            repositoryProvider.overrideWithValue(mockRepository),
            isLoggedInProvider.overrideWith(() => FakeIsLoggedInNotifier(true)),
            tokenProvider.overrideWithValue('token'),
          ],
        );
        addTearDown(loggedInContainer.dispose);

        loggedInContainer.read(permissionsNamesListProvider.notifier);
        await Future<void>.delayed(Duration.zero);
        await loggedInContainer
            .read(permissionsNamesListProvider.notifier)
            .loadPermissionsNamesList();

        expect(loggedInContainer.read(moduleGroupedPermissionsProvider), {
          'feed': ['write', 'read'],
          // A name without a dot keeps the full name as its own entry.
          'ticket': ['ticket'],
        });
      });
    });
  });
}
