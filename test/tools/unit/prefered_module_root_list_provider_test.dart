import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/tools/providers/prefered_module_root_list_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The notifier's build() fires an unawaited load: one microtask drain is
  /// what makes the loaded state visible to the assertions.
  Future<ProviderContainer> loadedContainer() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // First read runs build(), which schedules the load; the drain lets it
    // finish before the caller asserts.
    container.read(preferedModuleListRootProvider);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('build answers [] when nothing is stored', () async {
    final container = await loadedContainer();
    expect(container.read(preferedModuleListRootProvider), isEmpty);
  });

  test('load parses the stored CSV and an empty value resets to []', () async {
    SharedPreferences.setMockInitialValues({'prefered_modules': 'feed,vote'});
    var container = await loadedContainer();
    expect(container.read(preferedModuleListRootProvider), ['feed', 'vote']);

    SharedPreferences.setMockInitialValues({'prefered_modules': ''});
    container = await loadedContainer();
    expect(container.read(preferedModuleListRootProvider), isEmpty);
  });

  test('add appends, deduplicates and stops at two entries', () async {
    final container = await loadedContainer();
    final notifier = container.read(preferedModuleListRootProvider.notifier);

    await notifier.addPreferedModulesRoot('feed');
    expect(container.read(preferedModuleListRootProvider), ['feed']);

    // The duplicate guard: a second add of the same root is a no-op.
    await notifier.addPreferedModulesRoot('feed');
    expect(container.read(preferedModuleListRootProvider), ['feed']);

    await notifier.addPreferedModulesRoot('vote');
    expect(container.read(preferedModuleListRootProvider), ['feed', 'vote']);

    // The two-entry cap: a third root never enters the list.
    await notifier.addPreferedModulesRoot('tickets');
    expect(container.read(preferedModuleListRootProvider), ['feed', 'vote']);

    // And the persisted string matches the state.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prefered_modules'), 'feed,vote');
  });

  test(
    'remove deletes an entry, persists it, and ignores unknown roots',
    () async {
      SharedPreferences.setMockInitialValues({'prefered_modules': 'feed,vote'});
      final container = await loadedContainer();
      final notifier = container.read(preferedModuleListRootProvider.notifier);

      await notifier.removePreferedModulesRoot('feed');
      expect(container.read(preferedModuleListRootProvider), ['vote']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('prefered_modules'), 'vote');

      // The `contains` false arm: an unknown root changes nothing.
      await notifier.removePreferedModulesRoot('tickets');
      expect(container.read(preferedModuleListRootProvider), ['vote']);
      expect(prefs.getString('prefered_modules'), 'vote');
    },
  );

  test('removing from an empty store is a no-op', () async {
    // Nothing stored: the parse ternary takes its empty arm and the
    // contains guard rejects the removal outright.
    final container = await loadedContainer();
    final notifier = container.read(preferedModuleListRootProvider.notifier);

    await notifier.removePreferedModulesRoot('feed');

    expect(container.read(preferedModuleListRootProvider), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('prefered_modules'), isNull);
  });
}
