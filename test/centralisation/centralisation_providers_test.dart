import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/centralisation/class/module.dart';
import 'package:titan/centralisation/class/section.dart';
import 'package:titan/centralisation/providers/favorites_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('centralisation models', () {
    test('Module round-trips through JSON', () {
      // The late fields of Module.empty() cannot be assigned twice, so
      // modules are built from JSON directly.
      final module = Module.fromJson({
        'name': 'Cinema',
        'description': 'Movies',
        'icon': 'icon',
        'url': 'https://example.com',
      });

      final decoded = Module.fromJson(module.toJson());

      expect(decoded.name, 'Cinema');
      expect(decoded.description, 'Movies');
      expect(decoded.icon, 'icon');
      expect(decoded.url, 'https://example.com');
      // toJson defaults a missing liked to false.
      expect(decoded.liked, isFalse);
    });

    test(
      'Module.copyWith copies the name into the description (documented bug)',
      () {
        // Documented as-is: copyWith falls back to `this.name` instead of
        // `this.description`, so an untouched description silently becomes
        // the module name.
        final module = Module.fromJson({
          'name': 'Cinema',
          'description': 'Movies',
          'icon': 'i',
          'url': 'u',
        });

        final copied = module.copyWith(icon: 'new-icon');

        expect(copied.description, 'Cinema');
      },
    );

    test('Section.fromJson keeps the section name and modules', () {
      final section = Section.fromJson('Clubs', [
        {'name': 'Cinema', 'description': 'Movies', 'icon': 'i', 'url': 'u'},
      ]);

      expect(section.name, 'Clubs');
      expect(section.expanded, isTrue);
      expect(section.moduleList.single.name, 'Cinema');
    });
  });

  group('FavoritesNameNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      // Riverpod 3 auto-disposes unlistened providers and the save callback
      // runs after an async gap; keep the notifier alive.
      container.listen(favoritesNameProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    test('starts empty', () {
      expect(container.read(favoritesNameProvider), isEmpty);
    });

    test('loadFavorites restores the saved list', () async {
      SharedPreferences.setMockInitialValues({
        'favorites': ['a', 'b'],
      });
      final notifier = container.read(favoritesNameProvider.notifier);

      await notifier.loadFavorites();

      expect(container.read(favoritesNameProvider), ['a', 'b']);
    });

    test('toggleFavorite adds then removes a favorite', () async {
      final notifier = container.read(favoritesNameProvider.notifier);

      notifier.toggleFavorite('cinema');
      expect(container.read(favoritesNameProvider), ['cinema']);

      notifier.toggleFavorite('cinema');
      expect(container.read(favoritesNameProvider), isEmpty);

      await Future<void>.delayed(Duration.zero);
      final saved = (await SharedPreferences.getInstance()).getStringList(
        'favorites',
      );
      expect(saved, isEmpty);
    });

    test('reorderFavorites follows ReorderableListView semantics', () async {
      final notifier = container.read(favoritesNameProvider.notifier);
      notifier.toggleFavorite('a');
      notifier.toggleFavorite('b');
      notifier.toggleFavorite('c');
      expect(container.read(favoritesNameProvider), ['a', 'b', 'c']);

      // Dragging index 0 to index 2 lands it at index 1 (newIndex -= 1).
      notifier.reorderFavorites(0, 2);
      expect(container.read(favoritesNameProvider), ['b', 'a', 'c']);

      // Dragging downwards without adjustment.
      notifier.reorderFavorites(2, 0);
      expect(container.read(favoritesNameProvider), ['c', 'b', 'a']);

      await Future<void>.delayed(Duration.zero);
      final saved = (await SharedPreferences.getInstance()).getStringList(
        'favorites',
      );
      expect(saved, ['c', 'b', 'a']);
    });

    test(
      'reorderFavorites clamps out-of-range indices into a crash (insert range)',
      () {
        final notifier = container.read(favoritesNameProvider.notifier);
        notifier.toggleFavorite('a');

        // Documented as-is: inserting at an out-of-range index throws
        // RangeError instead of clamping.
        expect(() => notifier.reorderFavorites(0, 5), throwsA(anything));
      },
    );
  });
}
