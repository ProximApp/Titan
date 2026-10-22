import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';
import 'package:titan/super_admin/providers/permission_name_list_provider.dart';
import 'package:titan/super_admin/providers/permissions_list_provider.dart';
import 'package:titan/super_admin/providers/school_provider.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/user/providers/user_provider.dart';

import '../../shared/mock_openapi.dart';

class _FakeIsLoggedIn extends IsLoggedInProvider {
  @override
  bool build() => true;
}

class _DataUser extends UserNotifier {
  @override
  AsyncValue<CoreUser> build() => AsyncValue.data(CoreUser.empty());
}

class _ErrUser extends UserNotifier {
  @override
  AsyncValue<CoreUser> build() =>
      AsyncValue.error('user load failed', StackTrace.current);
}

class _DataPermissions extends PermissionsNotifier {
  _DataPermissions(this.granted);

  final List<CorePermission> granted;

  @override
  AsyncValue<List<CorePermission>> build() => AsyncValue.data(granted);
}

class _ErrPermissions extends PermissionsNotifier {
  @override
  AsyncValue<List<CorePermission>> build() =>
      AsyncValue.error('permissions load failed', StackTrace.current);
}

class _DataNames extends PermissionsNamesListNotifier {
  _DataNames(this.names);

  final List<String> names;

  @override
  AsyncValue<List<String>> build() => AsyncValue.data(names);
}

class _ErrNames extends PermissionsNamesListNotifier {
  @override
  AsyncValue<List<String>> build() =>
      AsyncValue.error('catalog load failed', StackTrace.current);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('schoolProvider', () {
    test('build starts empty and setSchool replaces the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(schoolProvider);
      expect(initial.name, '');
      expect(initial.id, '');

      container
          .read(schoolProvider.notifier)
          .setSchool(CoreSchool.empty().copyWith(id: 's1', name: 'EFREI'));

      expect(container.read(schoolProvider).id, 's1');
      expect(container.read(schoolProvider).name, 'EFREI');
    });
  });

  group('moduleRootListProvider error arms', () {
    test('surfaces a user load error', () {
      final container = ProviderContainer(
        overrides: [
          asyncUserProvider.overrideWith(_ErrUser.new),
          permissionsProvider.overrideWith(() => _DataPermissions(const [])),
          permissionsNamesListProvider.overrideWith(() => _DataNames(const [])),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(moduleRootListProvider);

      expect(result.hasError, isTrue);
      expect(result.error, 'user load failed');
    });

    test('surfaces a permissions load error', () {
      final container = ProviderContainer(
        overrides: [
          asyncUserProvider.overrideWith(_DataUser.new),
          permissionsProvider.overrideWith(() => _ErrPermissions()),
          permissionsNamesListProvider.overrideWith(() => _DataNames(const [])),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(moduleRootListProvider);

      expect(result.hasError, isTrue);
      expect(result.error, 'permissions load failed');
    });

    test('surfaces a permission-catalog load error', () {
      final container = ProviderContainer(
        overrides: [
          asyncUserProvider.overrideWith(_DataUser.new),
          permissionsProvider.overrideWith(() => _DataPermissions(const [])),
          permissionsNamesListProvider.overrideWith(_ErrNames.new),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(moduleRootListProvider);

      expect(result.hasError, isTrue);
      expect(result.error, 'catalog load failed');
    });
  });

  group('PermissionsNotifier', () {
    late MockOpenapi mockRepository;

    setUp(() => mockRepository = MockOpenapi());

    /// A signed-in session whose token is present is the only combination
    /// under which `build()` fires the load itself (line: `loadPermissions()`).
    ProviderContainer containerWithToken(String token) {
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          tokenProvider.overrideWithValue(token),
          isLoggedInProvider.overrideWith(_FakeIsLoggedIn.new),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build loads the list when the session carries a token', () async {
      final granted = [
        CorePermission.empty().copyWith(permissionName: 'core.admin'),
      ];
      when(() => mockRepository.permissionsGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), granted),
      );
      final container = containerWithToken('a-token');

      container.read(permissionsProvider);
      await pumpEventQueue();

      expect(container.read(permissionsProvider).value, granted);
    });

    test(
      'addGroupPermission posts the grant and merges it into the list',
      () async {
        // `update()` replaces by key (indexWhere), so the permission must
        // already exist in the list or the write lands on index -1 and the
        // error wrapper answers false.
        final existing = CorePermission.empty().copyWith(
          permissionName: 'core.admin',
        );
        when(() => mockRepository.permissionsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('body', 200), [existing]),
        );
        when(() => mockRepository.permissionsPost(body: any(named: 'body')))
            .thenAnswer(
              (_) async => chopper.Response(
                http.Response('body', 200),
                CorePermission.empty(),
              ),
            );
        final container = containerWithToken('a-token');
        final notifier = container.read(permissionsProvider.notifier);
        container.read(permissionsProvider);
        await pumpEventQueue();
        expect(container.read(permissionsProvider).value, [existing]);

        final granted = CorePermission.empty().copyWith(
          permissionName: 'core.admin',
          groups: ['g1'],
        );
        final result = await notifier.addGroupPermission(
          granted,
          CoreGroupPermission(permissionName: 'core.admin', groupId: 'g1'),
        );

        expect(result, isTrue);
        expect(container.read(permissionsProvider).value, [granted]);
        verify(() => mockRepository.permissionsPost(body: any(named: 'body')))
            .called(1);
      },
    );

    test('the derived maps fall back to empty while their sources load', () {
      // An empty token keeps both source notifiers parked in loading, which
      // is the only state the maybeWhen orElse arms see.
      final container = containerWithToken('');

      expect(container.read(mappedPermissionsProvider), isEmpty);
      expect(container.read(moduleGroupedPermissionsProvider), isEmpty);
    });
  });
}
