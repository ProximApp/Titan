import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:titan/navigation/providers/display_quit_popup.dart';
import 'package:titan/navigation/providers/navbar_animation.dart';
import 'package:titan/navigation/providers/navbar_module_list.dart';
import 'package:titan/navigation/providers/navbar_visibility_provider.dart';
import 'package:titan/navigation/providers/should_setup_provider.dart';
import 'package:titan/settings/providers/module_list_provider.dart';
import 'package:titan/tools/providers/prefered_module_root_list_provider.dart';

Module module(String root) => Module(
  getName: (_) => root,
  getDescription: (_) => 'description $root',
  root: root,
);

class FakeModulesNotifier extends ModulesNotifier {
  FakeModulesNotifier(this.initial);

  final List<Module> initial;

  @override
  List<Module> build() => initial;
}

class FakePreferedModuleRootListNotifier
    extends PreferedModuleRootListNotifier {
  FakePreferedModuleRootListNotifier(this.initial);

  final List<String> initial;

  @override
  List<String> build() => initial;
}

ProviderContainer moduleListContainer(
  List<Module> allModules,
  List<String> preferedRoots,
) {
  final container = ProviderContainer(
    overrides: [
      modulesProvider.overrideWith(() => FakeModulesNotifier(allModules)),
      preferedModuleListRootProvider.overrideWith(
        () => FakePreferedModuleRootListNotifier(preferedRoots),
      ),
    ],
  );
  // Riverpod 3 auto-disposes unlistened providers; keep the notifier alive.
  container.listen(navbarListModuleProvider, (_, _) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavbarVisibilityNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('starts visible', () {
      expect(container.read(navbarVisibilityProvider), isTrue);
    });

    test('show and hide update the state and the last requested state', () {
      final notifier = container.read(navbarVisibilityProvider.notifier);

      notifier.hide();
      expect(container.read(navbarVisibilityProvider), isFalse);
      expect(notifier.lastRequestedState, isFalse);

      notifier.show();
      expect(container.read(navbarVisibilityProvider), isTrue);
      expect(notifier.lastRequestedState, isTrue);
    });

    test('show and hide are no-ops when the state already matches', () {
      final notifier = container.read(navbarVisibilityProvider.notifier);

      // Already visible: show() must not flip lastRequestedState around.
      notifier.show();
      expect(notifier.lastRequestedState, isTrue);

      notifier.hide();
      notifier.hide();
      expect(container.read(navbarVisibilityProvider), isFalse);
      expect(notifier.lastRequestedState, isFalse);
    });

    test('toggle flips the visibility', () {
      final notifier = container.read(navbarVisibilityProvider.notifier);

      notifier.toggle();
      expect(container.read(navbarVisibilityProvider), isFalse);

      notifier.toggle();
      expect(container.read(navbarVisibilityProvider), isTrue);
    });

    test('forceShow reveals the bar even after hideWithoutAutoShow', () {
      final notifier = container.read(navbarVisibilityProvider.notifier);

      notifier.hideWithoutAutoShow();
      expect(container.read(navbarVisibilityProvider), isFalse);

      notifier.forceShow();
      expect(container.read(navbarVisibilityProvider), isTrue);
      expect(notifier.lastRequestedState, isTrue);
    });

    test('showTemporarily only reveals a hidden bar', () {
      final notifier = container.read(navbarVisibilityProvider.notifier);

      // Visible already: nothing changes.
      notifier.showTemporarily();
      expect(container.read(navbarVisibilityProvider), isTrue);

      notifier.hide();
      notifier.showTemporarily();
      expect(container.read(navbarVisibilityProvider), isTrue);
    });
  });

  group('ScrollDirectionNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('starts idle', () {
      expect(container.read(scrollDirectionProvider), ScrollDirection.idle);
    });

    test('an increasing offset scrolls down, a decreasing one scrolls up', () {
      final notifier = container.read(scrollDirectionProvider.notifier);

      notifier.updateScrollDirection(10);
      expect(container.read(scrollDirectionProvider), ScrollDirection.down);

      notifier.updateScrollDirection(4);
      expect(container.read(scrollDirectionProvider), ScrollDirection.up);
    });

    test('a zero delta keeps the previous direction', () {
      final notifier = container.read(scrollDirectionProvider.notifier);

      notifier.updateScrollDirection(10);
      notifier.updateScrollDirection(10);
      expect(container.read(scrollDirectionProvider), ScrollDirection.down);
    });

    test('resetDirection goes back to idle and forgets the offset', () {
      final notifier = container.read(scrollDirectionProvider.notifier);

      notifier.updateScrollDirection(100);
      expect(container.read(scrollDirectionProvider), ScrollDirection.down);

      notifier.resetDirection();
      expect(container.read(scrollDirectionProvider), ScrollDirection.idle);

      // The offset memory was reset to 0: a lower offset now reads as a
      // fresh downward scroll instead of an upward one.
      notifier.updateScrollDirection(50);
      expect(container.read(scrollDirectionProvider), ScrollDirection.down);
    });
  });

  group('NavbarAnimationProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // Controllers must be created inside the testWidgets body: their tickers
    // only work inside the tester's FakeAsync zone.
    AnimationController makeController() => AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
    );

    test('starts without a controller and guards every action', () {
      final notifier = container.read(navbarAnimationProvider.notifier);

      // None of these may throw while the controller is missing.
      notifier.toggle();
      notifier.show();
      notifier.hide();
      notifier.hideForModal();
      notifier.showForModal();

      expect(container.read(navbarAnimationProvider), isNull);
      expect(notifier.value, 0);
      expect(notifier.animation, isNull);
    });

    test('setController exposes the controller and its value', () {
      final notifier = container.read(navbarAnimationProvider.notifier);
      final controller = makeController();
      addTearDown(controller.dispose);

      notifier.setController(controller);

      expect(container.read(navbarAnimationProvider), same(controller));
      expect(notifier.value, 0);
    });

    // Tickers only tick between frames, so every animation step is driven
    // with pumpAndSettle; awaiting the TickerFuture would never resolve in a
    // test. A no-op call schedules no frame, so pumpAndSettle returns right
    // away and the value is asserted unchanged.
    testWidgets('toggle alternates between forward and reverse', (
      tester,
    ) async {
      final controller = makeController();
      addTearDown(controller.dispose);
      final notifier = container.read(navbarAnimationProvider.notifier);
      notifier.setController(controller);

      notifier.toggle();
      await tester.pumpAndSettle();
      expect(controller.value, 1);

      notifier.toggle();
      await tester.pumpAndSettle();
      expect(controller.value, 0);
    });

    testWidgets('show only forwards a dismissed controller', (tester) async {
      final controller = makeController();
      addTearDown(controller.dispose);
      final notifier = container.read(navbarAnimationProvider.notifier);
      notifier.setController(controller);

      notifier.show();
      await tester.pumpAndSettle();
      expect(controller.value, 1);

      // Already completed: show is a no-op.
      notifier.show();
      await tester.pumpAndSettle();
      expect(controller.value, 1);

      notifier.toggle(); // reverse
      await tester.pumpAndSettle();
      expect(controller.value, 0);

      notifier.show();
      await tester.pumpAndSettle();
      expect(controller.value, 1);
    });

    testWidgets('hide only reverses a completed controller', (tester) async {
      final controller = makeController();
      addTearDown(controller.dispose);
      final notifier = container.read(navbarAnimationProvider.notifier);
      notifier.setController(controller);

      // Dismissed already: hide is a no-op.
      notifier.hide();
      await tester.pumpAndSettle();
      expect(controller.value, 0);

      notifier.toggle(); // forward
      await tester.pumpAndSettle();
      expect(controller.value, 1);
      notifier.hide();
      await tester.pumpAndSettle();
      expect(controller.value, 0);
    });

    testWidgets(
      'hideForModal and showForModal are counted so nested modals keep the bar hidden',
      (tester) async {
        final controller = makeController();
        addTearDown(controller.dispose);
        final notifier = container.read(navbarAnimationProvider.notifier);
        notifier.setController(controller);
        notifier.show();
        await tester.pumpAndSettle();
        expect(controller.value, 1);

        notifier.hideForModal();
        expect(notifier.modalCount, 1);
        await tester.pumpAndSettle();
        expect(controller.value, 0);

        // A second modal opens: still hidden.
        notifier.hideForModal();
        expect(notifier.modalCount, 2);

        notifier.showForModal();
        expect(notifier.modalCount, 1);
        await tester.pumpAndSettle();
        expect(controller.value, 0);

        notifier.showForModal();
        expect(notifier.modalCount, 0);
        await tester.pumpAndSettle();
        expect(controller.value, 1);
      },
    );

    test('showForModal does not show the bar when no modal is open', () {
      final controller = makeController();
      addTearDown(controller.dispose);
      final notifier = container.read(navbarAnimationProvider.notifier);
      notifier.setController(controller);

      notifier.showForModal();

      expect(notifier.modalCount, -1);
    });
  });

  group('ModuleListNotifier', () {
    test(
      'build excludes the feed root, prefers saved roots and fills to max',
      () {
        final allModules = [
          module(FeedRouter.root), // must always be excluded
          module('/amap'),
          module('/phonebook'),
          module('/vote'),
          module('/cinema'),
        ];
        final container = moduleListContainer(allModules, ['/vote']);

        try {
          final modules = container.read(navbarListModuleProvider);

          expect(modules.map((m) => m.root), ['/vote', '/amap']);
        } finally {
          container.dispose();
        }
      },
    );

    test('build keeps the saved order and ignores unknown preferred roots', () {
      final allModules = [module('/amap'), module('/phonebook')];
      final container = moduleListContainer(allModules, [
        '/phonebook',
        '/ghost-root',
      ]);

      try {
        final modules = container.read(navbarListModuleProvider);

        expect(modules.map((m) => m.root), ['/phonebook', '/amap']);
      } finally {
        container.dispose();
      }
    });

    test('pushModule moves an existing module to the front', () {
      final allModules = [module('/amap'), module('/phonebook')];
      final container = moduleListContainer(allModules, []);
      final notifier = container.read(navbarListModuleProvider.notifier);

      try {
        notifier.pushModule(allModules[1]);

        expect(container.read(navbarListModuleProvider).map((m) => m.root), [
          '/phonebook',
          '/amap',
        ]);
      } finally {
        container.dispose();
      }
    });

    test(
      'pushModule inserts a new module and evicts the oldest beyond max',
      () {
        final allModules = [module('/amap'), module('/phonebook')];
        final container = moduleListContainer(allModules, []);
        final notifier = container.read(navbarListModuleProvider.notifier);

        try {
          notifier.pushModule(module('/vote'));

          expect(container.read(navbarListModuleProvider).map((m) => m.root), [
            '/vote',
            '/amap',
          ]);

          notifier.pushModule(module('/cinema'));

          expect(container.read(navbarListModuleProvider).map((m) => m.root), [
            '/cinema',
            '/vote',
          ]);
        } finally {
          container.dispose();
        }
      },
    );

    test('pushModule ignores the feed module entirely', () {
      final allModules = [module('/amap'), module('/phonebook')];
      final container = moduleListContainer(allModules, []);
      final notifier = container.read(navbarListModuleProvider.notifier);

      try {
        notifier.pushModule(FeedRouter.module);

        expect(container.read(navbarListModuleProvider).map((m) => m.root), [
          '/amap',
          '/phonebook',
        ]);
      } finally {
        container.dispose();
      }
    });
  });

  group('trivial bool providers', () {
    test('displayQuitProvider starts hidden and follows setDisplay', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(displayQuitProvider), isFalse);

      container.read(displayQuitProvider.notifier).setDisplay(true);
      expect(container.read(displayQuitProvider), isTrue);
    });

    test('shouldSetupProvider starts true and setShouldSetup latches it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(shouldSetupProvider), isTrue);

      container.read(shouldSetupProvider.notifier).setShouldSetup();
      expect(container.read(shouldSetupProvider), isFalse);
    });
  });
}
