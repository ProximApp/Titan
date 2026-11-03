import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../fixed_size_card_fixtures.dart';
import '../../shared/fixed_width_card_detector.dart';
import '../card_fixtures.dart';
import '../../mypayment/mypayment_fixtures.dart';

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
/// sweep runs at 360px (the default phone surface), 320px (the small end of
/// real Android widths) and 280px (a stress floor narrower than any device
/// the app ships to), narrowest last.
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
/// This re-exports the height sweep's exemptions from
/// `fixed_size_card_fixtures.dart` rather than re-declaring them, because the
/// two sweeps read ONE list — empty today: every candidate this detector finds
/// is mounted, so the map is only where a card that genuinely cannot be
/// mounted would go (with its reason). The width sweep does NOT import
/// `heightCardFixtures` — those are height-only cards the width detector does
/// not find, and a width sweep that mounted them would make its own
/// "mounted ⊆ found" ratchet a lie about what it covers.
const _notMounted = notMountedExemptions;

/// Cards pinned as overflowing at a given width, per pass. The sweep was
/// widened from 360-only to 320 (four cards — `TimelineItem`, `AdminPhCard`,
/// `SpeciesCard`, `UserTicketCard` — since fixed and dropped) and then to
/// 280. A pinned card is mounted anyway and its overflow is recorded at the
/// SOURCE instead of failing on it, which keeps that pass a real green
/// rather than a silent skip; when a fix makes one fit, nothing is recorded,
/// the pinned branch fails, and dropping the pin is the change the failure
/// asks for. Both sets are empty today: every candidate fits at every width
/// the sweep covers.
const _overflowPins = <int, Set<String>>{320: <String>{}, 280: <String>{}};

/// Every width the sweep mounts each card at, widest first. 360 is the
/// default phone surface, 320 the small end of real Android widths, and 280
/// the widened floor — narrower than any device the app ships to, kept as a
/// stress pass so a label that merely *barely* fits at 320 gets found by the
/// assertion rather than by a user with a long translated string.
const _sweepWidths = <int>[360, 320, 280];

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
    // The two endpoints the seed-library/vote cards fetch on build: their
    // providers' build() calls them and OVERWRITE a state seed once the
    // future lands, so the data has to come from the repository — a bare
    // `seedSharedMaps` is clobbered by the error and the cards die on
    // `firstWhere` over an empty list.
    when(() => scaffold.repository.seedLibrarySpeciesGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), speciesMap),
    );
    when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        SectionComplete.empty().copyWith(id: 'section-1', name: 'Section 1'),
      ]),
    );
    // …and the lists those sections own, so `SectionList.build()`'s rebuild
    // (triggered when campaignSectionsGet lands) finds one list per section
    // instead of an empty data list the vote card's `reduce` would throw on.
    when(() => scaffold.repository.campaignListsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        ListReturn.empty().copyWith(
          id: 'list-1',
          name: 'Liste A',
          section: SectionComplete.empty().copyWith(
            id: 'section-1',
            name: 'Section 1',
          ),
        ),
        ListReturn.empty().copyWith(
          id: 'list-2',
          name: 'Liste B',
          section: SectionComplete.empty().copyWith(
            id: 'section-1',
            name: 'Section 1',
          ),
        ),
      ]),
    );
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
          'to `cardFixtures` in test/tools/card_fixtures.dart, or a reason to '
          '`notMountedExemptions` in test/tools/fixed_size_card_fixtures.dart; '
          'the uncovered candidates are listed above, and '
          '`findFixedWidthCards()` in test/shared/fixed_width_card_detector.dart '
          'is what found them.',
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

  /// Each card mounted at every width in [_sweepWidths], narrowest last.
  for (final width in _sweepWidths) {
    for (final card in cardFixtures) {
      final cardId = '${card.source} ${card.className}';
      if (_notMounted.containsKey(cardId)) continue;
      final pinned = _overflowPins[width]?.contains(cardId) ?? false;

      testWidgets('$cardId fits a ${width}px phone', (tester) async {
        final container = scaffold.makeContainer(
          myStructures: [structureFixture('structure-1', longName, 'user-1')],
        );
        stubCardImages();
        // The species/section maps the seed-library and vote cards read on
        // build: without them their `firstWhere` throws `No element` and the
        // card dies before layout — the height sweep seeds them, and the
        // width sweep must too or those fixtures fail for the wrong reason.
        seedSharedMaps(container);
        addTearDown(container.dispose);

        final anim = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 200),
          value: 1,
        );
        addTearDown(anim.dispose);

        // A pinned overflow is recorded at the SOURCE: the binding's handler
        // would dump the overflow, the dump's inspector follow-ups ("Looking up
        // a deactivated widget's ancestor") become further exceptions, and
        // `tester.takeException` collapses a second throw into an opaque
        // "Multiple exceptions (2)" report — the trap
        // login_web_panels_widget_test.dart documents. Capturing here keeps the
        // pending list empty, so the pass stays green while the strings carry
        // what actually happened.
        final recorded = <String>[];
        if (pinned) {
          final previousOnError = FlutterError.onError;
          FlutterError.onError = (details) =>
              recorded.add(details.exceptionAsString());
          addTearDown(() => FlutterError.onError = previousOnError);
        }

        final cardWidget = card.build(container, anim);
        await scaffold.pumpWidgetApp(
          tester,
          Scaffold(
            body:
                card.wrap?.call(cardWidget) ??
                SingleChildScrollView(child: cardWidget),
          ),
          container,
          surface: Size(width.toDouble(), 640),
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
              '$cardId did not mount at ${width}px: either it threw during '
              'build, or the fixture it needs is missing.',
        );

        if (pinned) {
          // The pin is a claim that this card overflows here. Recording the
          // overflow is what keeps the pass a real green rather than a
          // silent skip; when a fix makes the card fit nothing is recorded,
          // the expect below fails, and dropping the pin is the change the
          // failure asks for.
          expect(
            recorded,
            isNotEmpty,
            reason:
                '$cardId no longer overflows at ${width}px - drop it from '
                '_overflowPins[$width]',
          );
          expect(
            recorded,
            anyElement(contains('overflowed')),
            reason:
                '$cardId is pinned as a ${width}px overflow but reported '
                'something that is not an overflow: $recorded',
          );
          // Anything the capture missed would otherwise fail this test at the
          // end — clear it the way login_web_panels_widget_test.dart does.
          tester.takeException();
        }

        await scaffold.unmountApp(tester);
      });
    }
  }

  test('the sweep records the cards pinned as overflowing', () {
    final found = findFixedWidthCards();
    final mounted = cardFixtures
        .map((c) => '${c.source} ${c.className}')
        .toSet();
    // `found` holds FixedWidthCard objects, so the string pins must be
    // compared against its string forms — `found.contains(pin)` is always
    // false against objects and would report every mounted pin as
    // "no longer fixed-width".
    final foundNames = found.map((f) => '$f').toSet();
    for (final entry in _overflowPins.entries) {
      final missed = entry.value
          .where((c) => mounted.contains(c))
          .where((c) => !foundNames.contains(c))
          .toList();
      expect(
        missed,
        isEmpty,
        reason:
            'a card pinned as a ${entry.key}px overflow is no '
            'longer fixed-width; either it stopped overflowing at that width '
            '(then drop it from _overflowPins) or the detector needs '
            'updating.',
      );
    }
  });
}
