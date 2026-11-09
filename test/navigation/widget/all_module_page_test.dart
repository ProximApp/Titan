import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/navigation/class/module.dart';
import 'package:titan/navigation/providers/navbar_module_list.dart';
import 'package:titan/navigation/ui/all_module_page.dart';
import 'package:titan/settings/providers/module_list_provider.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/tools/providers/prefered_module_root_list_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/route_mock_stub.dart';

/// The "all modules" page is the only place a student curates the two modules
/// the navbar keeps: the bookmark toggles a preferred root on and off, refuses
/// a third one, and the row itself pushes the module onto the navbar before
/// forwarding and navigating to it.
///
/// None of that ran in the suite — the page is deferred behind
/// `AppRouter.allModules` and only the boot redirects ever touched it.
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

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    final container = scaffold.makeContainer(
      userId: 'user-1',
      providerOverrides: [
        modulesProvider.overrideWith(
          () => _FakeModulesNotifier([
            module('home'),
            module('feed'),
            module('loan'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      const AllModulePage(),
      container: container,
      surface: const ui.Size(600, 900),
      appFonts: true,
    );
    return container;
  }

  /// The bookmark icon sitting in [root]'s row. The row also carries
  /// ListItem's trailing chevron, so the icon itself is what tells them apart.
  Finder bookmark(String root) => find.descendant(
    of: find.ancestor(
      of: find.text('Module $root'),
      matching: find.byType(Row),
    ),
    matching: find.byWidgetPredicate(
      (widget) => widget is HeroIcon && widget.icon == HeroIcons.bookmark,
    ),
  );

  HeroIconStyle? styleOf(WidgetTester tester, String root) =>
      tester.widget<HeroIcon>(bookmark(root)).style;

  testWidgets('every module is listed with its name and description', (
    tester,
  ) async {
    await pumpPage(tester);

    for (final root in ['home', 'feed', 'loan']) {
      expect(find.text('Module $root'), findsOneWidget);
      expect(find.text('About $root'), findsOneWidget);
    }
  });

  testWidgets('the bookmark toggles a preferred module on and off', (
    tester,
  ) async {
    final container = await pumpPage(tester);
    expect(container.read(preferedModuleListRootProvider), isEmpty);
    expect(styleOf(tester, 'loan'), HeroIconStyle.outline);

    await tester.tap(bookmark('loan'));
    await settle(tester, frames: 4);
    expect(container.read(preferedModuleListRootProvider), ['/loan']);
    expect(styleOf(tester, 'loan'), HeroIconStyle.solid);

    await tester.tap(bookmark('loan'));
    await settle(tester, frames: 4);
    expect(container.read(preferedModuleListRootProvider), isEmpty);
    expect(styleOf(tester, 'loan'), HeroIconStyle.outline);
  });

  testWidgets('a third preferred module is refused, not silently swapped', (
    tester,
  ) async {
    final container = await pumpPage(tester);

    await tester.tap(bookmark('home'));
    await settle(tester, frames: 4);
    await tester.tap(bookmark('feed'));
    await settle(tester, frames: 4);
    expect(container.read(preferedModuleListRootProvider), ['/home', '/feed']);

    await tester.tap(bookmark('loan'));
    await settle(tester, frames: 4);
    // The notifier keeps the first two and the icon stays hollow.
    expect(container.read(preferedModuleListRootProvider), ['/home', '/feed']);
    expect(styleOf(tester, 'loan'), HeroIconStyle.outline);
  });

  testWidgets('tapping a row pushes it onto the navbar and navigates', (
    tester,
  ) async {
    final container = await pumpPage(tester);

    await tester.tap(find.text('Module loan'));
    await settle(tester, frames: 6);

    expect(container.read(pathForwardingProvider).path, '/loan');
    expect(
      container.read(navbarListModuleProvider).map((m) => m.root),
      contains('/loan'),
    );
    expect(mock.navigated, contains('/loan'));
    // The navbar is shown again on arrival, whoever had hidden it.
    expect(tester.takeException(), isNull);
  });
}
