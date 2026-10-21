import 'dart:convert';

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

      // NOT attempted here: dragging a LikedCard to reorder. The items carry
      // their `ReorderableDelayedDragStartListener`, but under the test
      // binding the long-press drag never engages (started with
      // `startGesture` + a 600ms hold + `moveTo`, the same recipe as
      // Flutter's own reorderable tests, the state never moves — three
      // attempts, no swap and no proxyDecorator build). That leaves exactly
      // two lines uncovered in the module: `main_page.dart`'s proxyDecorator
      // closure, which only executes on an active drag frame. The reorder
      // PIPELINE itself is covered: `reorderFavorites` by its unit test, the
      // `onReorderItem:` wiring by the row above being present.
    },
  );
}
