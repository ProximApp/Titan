import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:titan/navigation/providers/display_quit_popup.dart';
import 'package:titan/navigation/providers/navbar_animation.dart';
import 'package:titan/navigation/ui/navigation_template.dart';
import 'package:titan/router.dart';
import 'package:titan/settings/providers/module_list_provider.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/tools/ui/styleguide/navbar.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/route_mock_stub.dart';

/// `NavigationTemplate` is the shell every routed page sits in: it mounts the
/// floating navbar for a signed-in session and the quit dialog while the flag
/// is up.
///
/// The navbar branch was entirely dark — the boot shells keep the session but
/// never reach a completed navbar animation with a signed-in path, so none of
/// the three item kinds (feed, a chosen module, "others") was ever tapped.
///
/// Two arms of the widget stay dark here, both by construction rather than by
/// omission:
///
///  * the notification boot (`setUpNotification` + `setShouldSetup`) needs
///    Firebase's platform channels, so the shared harness hands the template a
///    `shouldSetupProvider` that is already latched off. The service suite owns
///    that arm end to end in `test/service/integration/
///    setup_notification_integration_test.dart`, which renders this same
///    template with `runNotificationSetup: true` and its own Firebase fakes;
///  * the synthetic "Others" item's `getDescription` is never called at all:
///    `FloatingNavbar` reads only `getName`, and the one reader of a module
///    description, `all_module_page`, lists the user's real modules.
class _FakeModulesNotifier extends ModulesNotifier {
  _FakeModulesNotifier(this.all);

  final List<Module> all;

  @override
  List<Module> build() => all;
}

Module module(String name) => Module(
  getName: (_) => 'Module $name',
  getDescription: (_) => 'About $name',
  root: '/$name',
);

void main() {
  late IntegrationScaffold scaffold;
  late RecordingRouteMock mock;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    mock = RecordingRouteMock();
    QR.settings.mockRoute = mock;
  });

  tearDown(() => QR.settings.mockRoute = null);

  Future<ProviderContainer> pumpShell(
    WidgetTester tester, {
    bool signedIn = true,
  }) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      providerOverrides: [
        modulesProvider.overrideWith(
          () => _FakeModulesNotifier([module('loan'), module('vote')]),
        ),
      ],
    );
    addTearDown(container.dispose);

    // main.dart's wiring: the template unwraps `animation!` and only shows the
    // navbar once it is completed.
    final navbarController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    addTearDown(navbarController.dispose);
    container
        .read(navbarAnimationProvider.notifier)
        .setController(navbarController);

    if (signedIn) {
      container.read(pathForwardingProvider.notifier)
        ..login()
        ..forward(FeedRouter.root);
    }

    await pumpWidgetAt(
      tester,
      // The child is what gives the shell's Stack its size: a routed page
      // fills the screen, an empty SizedBox would collapse the navbar's
      // Positioned slot to zero and put it out of the hit-test bounds.
      const NavigationTemplate(child: SizedBox.expand()),
      container: container,
      surface: const ui.Size(600, 900),
    );
    return container;
  }

  testWidgets('a signed-in shell shows the feed, the modules and others', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.byType(FloatingNavbar), findsOneWidget);
    for (final label in ['Events', 'Module loan', 'Module vote', 'Others']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'navbar is missing $label',
      );
    }
  });

  testWidgets('without a logged-in path there is no navbar at all', (
    tester,
  ) async {
    await pumpShell(tester, signedIn: false);

    expect(find.byType(FloatingNavbar), findsNothing);
    // The page itself still renders: the shell only drops the chrome.
    expect(tester.takeException(), isNull);
  });

  testWidgets('each navbar entry forwards its path before navigating', (
    tester,
  ) async {
    final container = await pumpShell(tester);

    // A module entry navigates on the next frame, after its icon slide.
    await tester.tap(find.text('Module vote'));
    await settle(tester, frames: 6);
    expect(container.read(pathForwardingProvider).path, '/vote');
    expect(mock.navigated, contains('/vote'));

    await tester.tap(find.text('Others'));
    await settle(tester, frames: 6);
    expect(container.read(pathForwardingProvider).path, AppRouter.allModules);
    expect(mock.navigated, contains('/all_modules'));

    await tester.tap(find.text('Events'));
    await settle(tester, frames: 6);
    expect(container.read(pathForwardingProvider).path, FeedRouter.root);
    expect(mock.navigated, contains('/feed'));
  });

  testWidgets('the quit flag mounts the logout dialog over the shell', (
    tester,
  ) async {
    final container = await pumpShell(tester);
    expect(find.text('Log out'), findsNothing);

    container.read(displayQuitProvider.notifier).setDisplay(true);
    await settle(tester, frames: 4);

    // The shell's job is mounting it; the box's own buttons and its (dead)
    // backdrop handlers are pinned by navigation/quit_dialog_test.dart, which
    // pumps the dialog on its own instead of inside the shell's loose Stack.
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Do you want to log out?'), findsOneWidget);

    container.read(displayQuitProvider.notifier).setDisplay(false);
    await settle(tester, frames: 4);
    expect(find.text('Do you want to log out?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
