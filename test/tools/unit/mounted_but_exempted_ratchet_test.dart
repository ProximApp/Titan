import 'package:flutter_test/flutter_test.dart';

import '../../shared/card_fixtures.dart';
import '../../shared/fixed_size_card_fixtures.dart';

/// The registry-vs-exemption ratchet: a widget may be registered as mounted
/// OR exempted from mounting, never both at once.
///
/// [cardFixtures] is what every ratchet in the suite reads as "measured":
/// the width sweep mounts each entry at 360px and 320px, the height sweep
/// mounts the subset that also pins a height, the localization round-trip
/// mounts it under both locales, and the CardLayout mount ratchet counts the
/// file itself as a mounting site. `notMountedExemptions` does the opposite:
/// every one of those loops `continue`s past its keys, so an exempted
/// widget is never pumped at all.
///
/// Both at once is the `ModuleCard` failure shape: coverage claimed by the
/// registry while the exemption quietly suppresses the only mounts. The card
/// sat at 37/37 uncovered for several rounds behind a green sweep on an
/// exemption reason ("needs the modules map seeded") that was simply false —
/// because nothing in the suite could tell "registered" from "mounted".
/// The prose warnings in both files could not fail; this check can.
///
/// Two ways out when it fires, and only two:
/// * **Delete the exemption and mount it.** Seed what the card reads
///   (`seedSharedMaps` covers the shared maps; a card-specific provider is
///   stubbed inline in its own fixture, the way `ListListCard` stubs
///   `sectionsStatsProvider`).
/// * **Remove the fixture entry.** If the card genuinely cannot mount at
///   widget level, it is not mounted — so the registry must stop claiming
///   it, and the exemption alone accounts for it (the width/height
///   ratchets count `notMountedExemptions` keys as covered).
void main() {
  /// The set operation every assertion here uses, named so the liveness test
  /// below can prove it fires on a real overlap instead of trusting an
  /// intersection that could silently stop intersecting.
  Set<String> registeredButExempted(
    Iterable<String> registered,
    Iterable<String> exempted,
  ) => registered.toSet().intersection(exempted.toSet());

  test('no widget is registered as mounted and exempted at the same time', () {
    final registered = cardFixtures.map((c) => '${c.source} ${c.className}');
    final both = registeredButExempted(
      registered,
      notMountedExemptions.keys,
    ).toList()..sort();

    expect(
      both,
      isEmpty,
      reason:
          'these widgets are counted as mounted by every ratchet that reads '
          'cardFixtures, while notMountedExemptions SUPPRESSES their mount at '
          'runtime — the ModuleCard lie (coverage claimed, measurement never '
          'happening). Either delete the exemption and seed what the card '
          'reads, or remove the fixture entry so the registry stops claiming '
          'it is mounted. Offenders: $both',
    );
  });

  test('the two registries the check reads are real and comparable', () {
    expect(
      cardFixtures,
      isNotEmpty,
      reason:
          'an empty cardFixtures would make the intersection above pass '
          'vacuously — the registry is the mounted side of every sweep.',
    );
    // Exemption keys must use the fixtures' own '<lib path> <ClassName>'
    // shape, or an overlap could exist and never compare equal — the check
    // would be green while proving nothing.
    final shape = RegExp(r'^lib/.+\.dart [A-Z]\w*$');
    expect(
      notMountedExemptions.keys.where((k) => !shape.hasMatch(k)),
      isEmpty,
      reason:
          'an exemption key that is not a fixture id can never intersect '
          'cardFixtures, which would silently disable this ratchet.',
    );

    // The predicate itself, proven both ways: it reports a synthetic
    // overlap and stays quiet on disjoint registries.
    expect(
      registeredButExempted(
        const ['lib/a/widget_card.dart WidgetCard'],
        const ['lib/a/widget_card.dart WidgetCard'],
      ),
      isNotEmpty,
      reason: 'the overlap check must fire when the same id is on both sides.',
    );
    expect(
      registeredButExempted(
        const ['lib/a/widget_card.dart WidgetCard'],
        const ['lib/b/other_card.dart OtherCard'],
      ),
      isEmpty,
      reason: 'the overlap check must stay quiet on disjoint registries.',
    );
  });
}
