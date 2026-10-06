import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/fixed_size_card_fixtures.dart';
import '../../shared/fixed_width_card_detector.dart';
import '../../shared/card_fixtures.dart';

// The MODELS barrel on purpose: the umbrella `openapi.swagger.dart` also
// exports a `Size` ENUM, which shadows dart:ui's Size for every measurement
// in this file (and `show` would drop the generated copyWith extensions).

/// The standing overflow sweep for every card that fixes its own width.
///
/// `tool/detect_fixed_width_cards.py` found 65 widget classes under `lib/`
/// that hardcode a width AND put flex children in that box. Those are the
/// only shapes that overflow at phone width for a reason no padding tweak
/// can fix: the row is exactly as wide as the hardcoded box, so one
/// localized label longer than the author's screen and it is gone. Each is
/// mounted here alone at 360x640 and 320x640 — no router, no AppTemplate, no
/// navigation — so `flutter_test`'s fatal overflow assertion covers the
/// family as a whole rather than card by card as they are discovered. The
/// 320px pass is the small end of real Android widths: anything narrower than
/// the suite already tested.
///
/// Two things make the result trustworthy instead of noisy:
///
/// * **The app's real fonts.** `flutter_test` draws every glyph as a square
///   of the font size, so the default harness font measures every label one
///   to two times wider than a device does (convention 20). `appFonts: true`
///   registers the bundled Lato/Roboto faces, which turns the harness into
///   a device-width oracle. Verified both ways: the mypayment account card
///   overflows by 32px and 83px under the harness font at 360 and is clean
///   under Lato, which is why the sweep is green rather than a wall of
///   phantom failures.
///
/// * **A coverage ratchet.** The first test here re-runs the detector and
///   fails if any candidate is missing from [cardFixtures], so a new fixed-width
///   card cannot land in `lib/` without someone mounting it. That is what
///   makes this a check rather than a snapshot.
///
/// The data is deliberately adversarial — long names, five-figure amounts,
/// the full label set — because the strings that overflow are the ones
/// nobody types in a demo.

/// Cards the sweep deliberately does NOT mount, and why.
///
/// Every entry is a card that cannot be given a fixture here: its content
/// comes from a page-level provider map the shared container does not seed,
/// so `firstWhere` over an empty list throws and the card never lays out.
/// They are listed rather than dropped so the ratchet below still accounts
/// for all 64 candidates, and so nobody has to rediscover why they are
/// missing. Each is exercised at page level by its module's integration
/// test instead.
///
/// An entry here SUPPRESSES the mount even though the card has a `cardFixtures`
/// entry and a builder ready for it, so an exemption is a promise about a
/// card that could otherwise be mounted. That promise is only as good as its
/// reason, and nothing here can check a reason is true - which is how
/// `ModuleCard` sat exempted for several rounds with `module_card.dart` at
/// 37/37 uncovered and this sweep green. Its stated reason ("needs the
/// modules map seeded") was simply false: `favoritesNameProvider.build()`
/// returns `[]`, so the card needs nothing, and what it actually needed was
/// a bounded parent (its `Column` holds an `Expanded`, which asserts under
/// this sweep's unbounded scroll view). The exemption is deleted rather than
/// satisfied; the card is really mounted here via its `wrap` parent and at
/// widget level in
/// `test/centralisation/widget/centralisation_cards_widget_test.dart`.
/// Treat a reason in this map as unverified until a test mounts the card.
///
/// This is the SAME five entries as the height sweep's `_notMounted` in
/// `fixed_size_card_fixtures.dart`; the width sweep re-exports it from there
/// rather than re-declaring it, because the five are shared cards that BOTH
/// sweeps read from. The width sweep does NOT import `heightCardFixtures` —
/// those are height-only cards the width detector does not find, and a width
/// sweep that mounted them would make its own "mounted ⊆ found" ratchet a lie
/// about what it covers.
const _notMounted = notMountedExemptions;

/// A 404 for every logo/picture the cards request: the image widgets render
/// their error state, which is what a device shows for a missing asset, and
/// nothing reaches the network.
final _missingImage = chopper.Response(http.Response('', 404), <int>[]);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The five endpoints these cards fetch on mount. They are all logos and
  /// pictures: `MapNotifier.autoLoad` calls them the moment the card builds,
  /// and an unstubbed mocktail method returns null where a `Future` is
  /// expected, so the card dies before it ever lays out — which would make
  /// "no overflow" true for the wrong reason. A 404 keeps the image widget
  /// in its error state, which is what a device shows for a missing logo.
  void stubCardImages() {
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository
          .recommendationRecommendationsRecommendationIdPictureGet(
            recommendationId: any(named: 'recommendationId'),
          ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => _missingImage);
  }

  test('the sweep covers every fixed-width card under lib/', () {
    final found = findFixedWidthCards();
    final mounted = cardFixtures
        .map((c) => '${c.source} ${c.className}')
        .toSet();
    final uncovered = found
        .map((c) => '$c')
        .where((c) => !mounted.contains(c) && !_notMounted.containsKey(c))
        .toList();

    expect(
      uncovered,
      isEmpty,
      reason:
          'these fixed-width cards are not mounted by this sweep. Add an entry '
          'to cardFixtures in test/tools/widget/fixed_width_cards_test.dart, or run '
          '`python3 tool/detect_fixed_width_cards.py` for their constructors.',
    );
    // An exemption with no reason is a silent hole; make it a failure.
    expect(
      _notMounted.values.where((r) => r.trim().isEmpty),
      isEmpty,
      reason:
          'every entry in _notMounted must say why the card cannot be '
          'mounted here',
    );
    expect(
      mounted,
      everyElement(isIn(found.map((c) => '$c').toSet())),
      reason:
          'the sweep mounts a card the detector no longer finds; it either '
          'stopped being fixed-width (then drop the entry) or the detector '
          'needs updating.',
    );
  });

  /// Smallest realistic Android width; narrower than the 360px pass above and
  /// the one real device width the suite already tested, so anything that fits
  /// here fits on every phone the app is expected to run on.
  for (final card in cardFixtures) {
    if (_notMounted.containsKey('${card.source} ${card.className}')) continue;
    testWidgets('${card.source} ${card.className} fits a 360px phone', (
      tester,
    ) async {
      final container = scaffold.makeContainer(
        myStructures: [structure('structure-1', longName, 'user-1')],
      );
      stubCardImages();
      addTearDown(container.dispose);

      final anim = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 200),
        value: 1,
      );
      addTearDown(anim.dispose);

      final cardWidget = card.build(container, anim);
      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body:
              card.wrap?.call(cardWidget) ??
              SingleChildScrollView(child: cardWidget),
        ),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 4);

      // Non-vacuity: a card that silently built nothing satisfies "no
      // overflow" for the wrong reason - and half of them used to, because
      // an unstubbed repository call threw during build and left the tree
      // empty. Look for the card itself.
      expect(
        find.byType(card.type),
        findsOneWidget,
        reason:
            '${card.source} ${card.className} did not mount: either it '
            'threw during build, or the fixture it needs is missing.',
      );

      await scaffold.unmountApp(tester);
    });

    testWidgets('${card.source} ${card.className} fits a 320px phone', (
      tester,
    ) async {
      final container = scaffold.makeContainer(
        myStructures: [structure('structure-1', longName, 'user-1')],
      );
      stubCardImages();
      addTearDown(container.dispose);

      final anim = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 200),
        value: 1,
      );
      addTearDown(anim.dispose);

      final cardWidget = card.build(container, anim);
      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body:
              card.wrap?.call(cardWidget) ??
              SingleChildScrollView(child: cardWidget),
        ),
        container,
        surface: const Size(320, 640),
        appFonts: true,
      );
      await settle(tester, frames: 4);

      expect(
        find.byType(card.type),
        findsOneWidget,
        reason:
            '${card.source} ${card.className} did not mount at 320px: '
            'either it threw during build, or the fixture it needs is missing.',
      );

      await scaffold.unmountApp(tester);
    });
  }

  // 320px overflow ratchet: the four cards above that already overflowed at
  // 320 when this file was widened are pinned here so the 320 pass is a real
  // green rather than a silent skip, and so a later fix that makes them fit is
  // the thing that removes them.
  const _320overflow = {
    'lib/feed/ui/pages/main_page/time_line_item.dart TimelineItem',
    'lib/ph/ui/pages/admin_page/admin_ph_card.dart AdminPhCard',
    'lib/seed-library/ui/pages/species_page/species_card.dart SpeciesCard',
    'lib/tickets/ui/components/user_ticket_card.dart UserTicketCard',
  };

  test('the 320px sweep records the cards that still overflow at 320px', () {
    final found = findFixedWidthCards();
    final mounted = cardFixtures
        .map((c) => '${c.source} ${c.className}')
        .toSet();
    final missed = _320overflow
        .where((c) => mounted.contains(c))
        .where((c) => !found.contains(c))
        .toList();
    expect(
      missed,
      isEmpty,
      reason:
          'a card pinned as a 320px overflow is no longer fixed-width; '
          'either it stopped overflowing at 320 (then drop it from '
          '_320overflow) or the detector needs updating.',
    );
  });
}
