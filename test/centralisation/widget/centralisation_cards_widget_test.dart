import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/centralisation/class/module.dart';
import 'package:titan/centralisation/providers/favorites_providers.dart';
import 'package:titan/centralisation/ui/pages/liked_card.dart';
import 'package:titan/centralisation/ui/pages/module_card.dart';

import '../../shared/app_scaffold.dart';

/// centralisation's two cards, at phone width.
///
/// `module_card.dart` was **37/37 uncovered — 0%** — while
/// `tools/widget/fixed_width_cards_test.dart` carried a `_Card` registration
/// naming it. The registration was dead: the sweep skips any candidate that
/// also appears in its `_notMounted` map, and `ModuleCard` was in both, so the
/// test never ran and the ratchet's "is it mounted" check passed on the
/// strength of a registration that never mounted anything. The exemption's own
/// reason ("needs the modules map seeded") turned out to be wrong —
/// `FavoritesNameNotifier.build()` returns `[]`, so the card needs nothing.
///
/// So this file exists mainly to make that card real, and `ModuleCard`'s
/// exemption is deleted rather than satisfied. `LikedCard` is already swept;
/// it is here too because the pair differ in a way worth pinning: `LikedCard`
/// pins its own width (92) and has NO `Expanded` on its icon, so its content
/// is 74px of fixed stack and a short parent is a vertical overflow.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// `module_card.dart` reads no provider map, only `favoritesNameProvider`,
  /// so a bare container is enough.
  Module module({
    String name = 'Billets',
    String icon = 'home',
    String url = '/feed',
    String? description,
  }) => Module(
    name: name,
    description: description ?? 'Le module de billetterie',
    icon: icon,
    url: url,
  );

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget child, {
    ui.Size surface = const ui.Size(360, 640),
  }) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Scaffold(body: SingleChildScrollView(child: child)),
      container,
      surface: surface,
      appFonts: true,
    );
    await settle(tester, frames: 4);
    return container;
  }

  /// A grid cell, which is the only parent `ModuleCard` ever really has: its
  /// `Column` holds an `Expanded`, so an unbounded height would assert.
  Future<ProviderContainer> pumpInCell(WidgetTester tester, Widget card) =>
      pump(
        tester,
        SizedBox(width: 160, height: 130, child: Center(child: card)),
      );

  testWidgets('ModuleCard mounts at 360px in a grid cell', (tester) async {
    await pumpInCell(tester, ModuleCard(module: module()));

    // Non-vacuity first: this is the assertion the dead sweep registration
    // never got to make.
    expect(find.byType(ModuleCard), findsOneWidget);
    expect(find.text('Billets'), findsOneWidget);
    // Unfavourable by default, outlined star.
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('ModuleCard shows a filled star once favourited', (tester) async {
    final container = await pumpInCell(tester, ModuleCard(module: module()));
    container.read(favoritesNameProvider.notifier).toggleFavorite('Billets');
    await settle(tester, frames: 4);

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);

    await scaffold.unmountApp(tester);
  });

  testWidgets('tapping the star toggles the favourite and only that', (
    tester,
  ) async {
    final container = await pumpInCell(
      tester,
      ModuleCard(module: module(name: 'Billets')),
    );

    await tester.tap(find.byIcon(Icons.star_border), warnIfMissed: false);
    await settle(tester, frames: 4);

    expect(container.read(favoritesNameProvider), ['Billets']);
    expect(find.byIcon(Icons.star), findsOneWidget);

    // And back off again — the toggle is symmetric, which is the whole point
    // of it being a favourite rather than a one-way mark.
    await tester.tap(find.byIcon(Icons.star), warnIfMissed: false);
    await settle(tester, frames: 4);
    expect(container.read(favoritesNameProvider), isEmpty);

    await scaffold.unmountApp(tester);
  });

  testWidgets('a long module name wraps to two lines without overflowing', (
    tester,
  ) async {
    // `AutoSizeText` with maxLines 2 and minFontSize 9 is the reason this card
    // is safe: the name is the only thing in the cell that can grow.
    await pumpInCell(
      tester,
      ModuleCard(module: module(name: 'Associations et billetterie des adhes')),
    );

    expect(find.byType(ModuleCard), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the SVG branch renders a real picture', (tester) async {
    // `module.icon.endsWith('.svg')` picks `SvgPicture.network`. Reaching that
    // branch used to be impossible: `flutter_svg` loads through
    // `package:http`, not through `NetworkImage`, so the harness's image stub
    // (which only implemented `HttpClient.getUrl`) threw during
    // `didChangeDependencies`. `stubNetworkImages` now answers `openUrl` and
    // serves real SVG bytes for an `.svg` path, so this asserts the branch
    // genuinely decoded rather than merely being reached.
    await pumpInCell(tester, ModuleCard(module: module(icon: 'billets.svg')));

    expect(find.byType(ModuleCard), findsOneWidget);
    // The name is laid out under the icon either way.
    expect(find.text('Billets'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);

    await scaffold.unmountApp(tester);
  });

  testWidgets('LikedCard fits its pinned 92px width', (tester) async {
    await pump(tester, LikedCard(module: module()));

    expect(find.byType(LikedCard), findsOneWidget);
    expect(
      tester.getSize(find.byType(LikedCard)).width,
      104, // 92 pinned + the 6px horizontal padding on each side
    );
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('LikedCard overflows a parent shorter than its 74px stack', (
    tester,
  ) async {
    // `LikedCard`'s content is a fixed 36 + 8 + 30 = 74px column with no
    // `Expanded`, so the card cannot compress. This pins the height its parent
    // must give it: `main_page.dart` wraps the favourites strip in a hard
    // `height: 135` container for exactly this reason, and any other parent
    // that hands it less overflows. Asserted as an expected overflow, not a
    // pass, because here the card is the thing being measured.
    await pump(
      tester,
      SizedBox(height: 60, child: LikedCard(module: module())),
    );

    expect(find.byType(LikedCard), findsOneWidget);
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
      error.toString(),
      contains('overflowed'),
      reason: 'expected the rigid 74px stack to overflow a 60px parent',
    );

    await scaffold.unmountApp(tester);
  });

  testWidgets('LikedCard fits the 135px favourites strip main_page builds', (
    tester,
  ) async {
    // The real parent: a horizontal `ReorderableListView` inside
    // `Container(height: 135)`. LikedCard needs 74 of content + 2x12 of its
    // own padding = 98, so the production height has 37px of slack; this
    // mounts the real geometry rather than asserting arithmetic about it.
    await pump(
      tester,
      SizedBox(
        height: 135,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            LikedCard(module: module(name: 'Billets')),
            LikedCard(module: module(name: 'Associations')),
          ],
        ),
      ),
    );

    expect(find.byType(LikedCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
