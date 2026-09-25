import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/admin/providers/is_admin_provider.dart';
import 'package:titan/settings/providers/logs_tab_provider.dart';
import 'package:titan/settings/providers/module_list_provider.dart';
import 'package:titan/super_admin/providers/is_super_admin_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/user/providers/user_provider.dart';

class MockLogger extends Mock implements Logger {}

class FakeModulesNotifier extends ModulesNotifier {
  @override
  List<Module> build() {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogTabsNotifier', () {
    test('defaults to the log tab and follows switches', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(logTabProvider), LogTabs.log);

      container.read(logTabProvider.notifier).setLogTabs(LogTabs.notification);
      expect(container.read(logTabProvider), LogTabs.notification);

      container.read(logTabProvider.notifier).setLogTabs(LogTabs.log);
      expect(container.read(logTabProvider), LogTabs.log);
    });
  });

  group('ModulesNotifier', () {
    late MockLogger mockLogger;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockLogger = MockLogger();
      container = ProviderContainer(
        overrides: [
          loggerProvider.overrideWithValue(mockLogger),
          userProvider.overrideWithValue(CoreUser.empty()),
          isAdminProvider.overrideWithValue(false),
          isSuperAdminProvider.overrideWithValue(false),
          moduleRootListProvider.overrideWithValue(
            const AsyncValue.data([
              'amap',
              'booking',
              'phonebook',
              'purchases',
              'vote',
            ]),
          ),
        ],
      );
      // Riverpod 3 auto-disposes providers without listeners, and
      // saveModules' fire-and-forget SharedPreferences callback then hits a
      // disposed ref. An active listener keeps the notifier alive.
      container.listen(modulesProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    test('loadModules keeps only the granted roots', () async {
      final notifier = container.read(modulesProvider.notifier);

      await notifier.loadModules(['/amap', '/phonebook']);

      final roots = container.read(modulesProvider).map((m) => m.root).toList();
      expect(roots, containsAll(['/amap', '/phonebook']));
      expect(roots, isNot(contains('/booking')));
      expect(roots, isNot(contains('/vote')));
    });

    test(
      'getModuleByRoot falls back to the first module on unknown root',
      () async {
        final notifier = container.read(modulesProvider.notifier);
        await notifier.loadModules(['/amap', '/phonebook']);
        final all = container.read(modulesProvider);

        expect(notifier.getModuleByRoot('/amap'), same(all.first));

        final fallback = notifier.getModuleByRoot('/does-not-exist');
        expect(fallback, same(all.first));
      },
    );

    test('toggleModule removes then re-adds the module', () async {
      final notifier = container.read(modulesProvider.notifier);
      await notifier.loadModules(['/amap', '/phonebook', '/vote']);
      final amap = notifier.getModuleByRoot('/amap');

      notifier.toggleModule(amap);
      expect(
        container.read(modulesProvider).map((m) => m.root),
        isNot(contains('/amap')),
      );

      notifier.toggleModule(amap);
      expect(
        container.read(modulesProvider).map((m) => m.root),
        contains('/amap'),
      );
    });

    test('sortModules orders the visible list like the full catalog', () async {
      final notifier = container.read(modulesProvider.notifier);
      await notifier.loadModules(['/vote', '/amap']);

      notifier.sortModules();

      final roots = container.read(modulesProvider).map((m) => m.root).toList();
      // The catalog (allModules) order wins over the current display order.
      expect(roots.indexOf('/amap'), lessThan(roots.indexOf('/vote')));
    });

    test(
      'reorderModules moves a module and persists the new catalog order',
      () async {
        final notifier = container.read(modulesProvider.notifier);
        await notifier.loadModules(['/amap', '/phonebook', '/vote']);
        // loadModules appends /settings (and admin pages for admins) at the end.
        expect(container.read(modulesProvider).map((m) => m.root).toList(), [
          '/amap',
          '/phonebook',
          '/vote',
          '/settings',
        ]);

        notifier.reorderModules(0, 2);

        final roots = container
            .read(modulesProvider)
            .map((m) => m.root)
            .toList();
        // Reordering follows ReorderableListView semantics: moving index 0 to
        // 2 lands it at index 1 (newIndex -= 1). allModules is reordered in
        // place and the state follows it.
        expect(roots, ['/phonebook', '/amap', '/vote', '/settings']);
        final savedOrder = (await SharedPreferences.getInstance())
            .getStringList('allModules');
        expect(savedOrder, ['/phonebook', '/amap', '/vote', '/settings']);
      },
    );

    test('build seeds the state from the granted module roots', () async {
      // loadModules runs asynchronously inside build, so wait for the
      // SharedPreferences roundtrip before asserting.
      container.read(modulesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final roots = container.read(modulesProvider).map((m) => m.root).toList();
      // Granted roots keep their catalog order; /settings is appended by
      // loadModules and every ungranted module is dropped.
      expect(roots, [
        '/amap',
        '/booking',
        '/phonebook',
        '/purchases',
        '/vote',
        '/settings',
      ]);
    });
  });
}
