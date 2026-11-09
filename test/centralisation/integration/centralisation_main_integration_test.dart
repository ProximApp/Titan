import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:titan/centralisation/providers/favorites_providers.dart';
import 'package:titan/centralisation/router.dart';
import 'package:titan/centralisation/ui/pages/liked_card.dart';
import 'package:titan/centralisation/ui/pages/main_page.dart';
import 'package:titan/centralisation/ui/pages/module_card.dart';
import 'package:titan/centralisation/ui/pages/section_list.dart';

import '../../shared/app_scaffold.dart';

/// `/centralisation` end to end. links.json comes from package:http (not the
/// mocked Openapi), so the payload is served through `http.runWithClient`
/// around the pump: the notifier's fire-and-forget `initState` creates the
/// request inside that zone, and the MockClient answers it there.
///
/// Order (convention 2/10): both tests land on the root through pumpApp's
/// initialPath; the router's static `module` closures are read only from the
/// already-rendered page, never by navigating anywhere.
final String payload = jsonEncode({
  'Clubs': [
    {
      'name': 'Billets',
      'description': 'Le module de billetterie',
      'icon': 'bird.png',
      'url': 'https://tickets.example.com',
    },
  ],
  'Services': [
    {
      'name': 'Print',
      'description': 'Impression',
      'icon': 'print.png',
      'url': 'https://print.example.com',
    },
  ],
});

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // The grid cards' icons are Image.network, and pumpApp does not install
    // the harness's one-pixel client (only pumpWidgetAt does): raw
    // ImageResourceService 400s would fail both tests below.
    stubNetworkImages();
  });

  Future<ProviderContainer> pumpCentralisation(
    WidgetTester tester, {
    List<String> favorites = const [],
  }) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final favoritesNotifier = container.read(favoritesNameProvider.notifier);
    for (final name in favorites) {
      favoritesNotifier.toggleFavorite(name);
    }
    scaffold.setWideSurface(tester);

    final client = MockClient((request) async => http.Response(payload, 200));
    await http.runWithClient(
      () => scaffold.pumpApp(
        tester,
        container,
        initialPath: CentralisationRouter.root,
        pumpAndSettle: false,
      ),
      () => client,
    );
    await settle(tester);
    return container;
  }

  testWidgets('deep link renders both sections and their cards', (
    tester,
  ) async {
    await pumpCentralisation(tester);

    expect(find.byType(CentralisationMainPage), findsOneWidget);
    expect(find.byType(SectionList), findsNWidgets(2));
    expect(find.text('Clubs'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.byType(ModuleCard), findsNWidgets(2));
    expect(find.text('Billets'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    // No favourite seeded: the reorderable strip stays out of the tree.
    expect(find.byType(LikedCard), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a seeded favourite fills the strip and the router module texts resolve',
    (tester) async {
      await pumpCentralisation(tester, favorites: ['Billets', 'Print']);

      // The favourites branch of main_page: strip above the sections, the
      // same module now carrying a LikedCard as well as its grid cell.
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(
        find.byType(LikedCard),
        findsNWidgets(2),
        reason: 'one LikedCard per seeded favourite',
      );
      expect(find.byType(ModuleCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      // CentralisationRouter.module's name/description closures exist only
      // for the navigation surface; nothing on this page reads them, so
      // they are answered directly from a real app context instead of
      // assumed covered by the deep link above.
      final context = tester.element(find.byType(CentralisationMainPage));
      expect(CentralisationRouter.module.getName(context), isNotEmpty);
      expect(CentralisationRouter.module.getDescription(context), isNotEmpty);
      expect(CentralisationRouter.module.root, CentralisationRouter.root);

      // The drag that reorders the strip has its own test below: it starts on
      // the platform's drag handle, because a long press on the CARD opens
      // the link details instead.
    },
  );

  testWidgets('a stale favourite does not take the page down', (tester) async {
    // The favourites are persisted (SharedPreferences "favorites") while
    // the modules come from links.json, so a module renamed or dropped
    // server-side leaves behind a name nothing resolves any more. The
    // unguarded `modules.firstWhere((module) => module.name == name)` in
    // main_page threw "Bad state: No element" out of build and killed every
    // section on the page.
    await pumpCentralisation(tester, favorites: ['Ghost module']);

    expect(tester.takeException(), isNull);
    expect(find.byType(CentralisationMainPage), findsOneWidget);
    expect(find.byType(SectionList), findsNWidgets(2));
    // The stale favourite resolves to nothing, so it contributes no card —
    // but the real modules still render.
    expect(find.byType(LikedCard), findsNothing);
    expect(find.byType(ModuleCard), findsNWidgets(2));
    expect(find.text('Billets'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
  });

  testWidgets('dragging a favourite by its handle reorders the strip', (
    tester,
  ) async {
    // The list only builds drag handles on a desktop platform: on a phone the
    // whole card is the long-press target, and its own long press opens the
    // link details first. Desktop is therefore where a reorder starts, and a
    // desktop build is what this test renders.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    await pumpCentralisation(tester, favorites: ['Billets', 'Print']);
    expect(find.byType(LikedCard), findsNWidgets(2));
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

    // Drag the first favourite past the second one's midpoint. Each step needs
    // its own frame: the list only re-evaluates the drop slot on a drag update
    // frame, and a single large move coalesces into one.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_handle).first),
    );
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    // The strip followed the drag: the second favourite is now first, and the
    // persisted order moved with it.
    expect(
      tester
          .widgetList<LikedCard>(find.byType(LikedCard))
          .map((card) => card.module.name),
      ['Print', 'Billets'],
    );
    expect(tester.takeException(), isNull);

    // Foundation's debug hooks are verified after the body, so the platform
    // override has to be handed back before the test ends.
    debugDefaultTargetPlatformOverride = null;
  });
}
