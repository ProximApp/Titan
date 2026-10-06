import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/seed-library/providers/species_list_provider.dart';
import 'package:titan/vote/providers/sections_list_provider.dart';

/// Cards the sweeps deliberately do NOT mount, and why.
///
/// Every entry is a card whose content comes from a page-level provider map
/// this shell does not seed, so `firstWhere` over an empty list throws and the
/// card never lays out. They are listed rather than dropped so the ratchet
/// still accounts for all candidates, and so nobody has to rediscover why they
/// are missing.
///
/// An entry here SUPPRESSES a mount even though a builder exists for it, so the
/// promise is only as good as the reason — and nothing here can check a reason
/// is true. That is how `ModuleCard` sat exempt for several rounds with
/// `module_card.dart` at 37/37 uncovered and the sweep green. Its stated reason
/// ("needs the modules map seeded") was simply false: `favoritesNameProvider`
/// returns `[]`, so the card needed nothing, and what it actually needed was a
/// bounded parent (its `Column` holds an `Expanded`, which asserts under this
/// sweep's unbounded scroll view). The exemption was deleted rather than
/// satisfied; the card is really mounted here via its `wrap` parent and at
/// widget level in
/// `test/centralisation/widget/centralisation_cards_widget_test.dart`.
/// Treat a reason in this map as unverified until some test mounts the card.
///
/// This is the SAME list both sweeps read from; never duplicate it.
const notMountedExemptions = <String, String>{
  /// `FiltersBar` reads `syncSpeciesListProvider` (shared seed) AND
  /// `syncSpeciesTypeListProvider` (card's own stub) plus the difficulty/season
  /// value lists. The shared seed only covers the species map, so the bar still
  /// asserts on the species-type dropdown value.
  'lib/seed-library/ui/components/filters_bar.dart FiltersBar':
      'needs syncSpeciesTypeListProvider and the difficulty/season value lists, '
      'which are page-level',

  /// `PersonalPlantCard` reads the species map (shared seed) and then needs the
  /// plant's own species id to resolve against it — the plant fixture still needs
  /// a valid species id, and that is the card's own stub.
  'lib/seed-library/ui/pages/plants_page/personal_plant_card.dart '
          'PersonalPlantCard':
      'needs a species fixture',

  /// `PlantCard` reads the species map (shared seed) and then needs the plant's
  /// own species id to resolve against it — the plant fixture still needs a valid
  /// species id, and that is the card's own stub.
  'lib/seed-library/ui/pages/stock_page/plant_card.dart PlantCard':
      'needs a species fixture',

  /// `ListListCard` indexes the section map (shared seed) by section and then
  /// reads `sectionsStatsProvider`. The shared seed only covers the first, so the
  /// card still throws inside `build` without the stats-provider stub, which is
  /// the card's own stub.
  'lib/vote/ui/pages/main_page/list_list_card.dart ListListCard':
      'needs sectionsStatsProvider seeded',

  /// `OrderSection` reads the amap orders/associations maps, which are
  /// page-scoped and not part of this shared seed — it stays exempted.
  'lib/amap/ui/pages/main_page/orders_section.dart OrderSection':
      'needs the orders and associations maps seeded, which are page-scoped',
};

/// The species map the seed-library cards read from
/// `syncSpeciesListProvider` on mount.
///
/// This is the fixture a sweep (or any other test) needs before it can mount
/// `PersonalPlantCard`, `PlantCard`, or `FiltersBar` — the three cards in
/// `notMountedExemptions` whose reason is "needs a species fixture". Without it
/// those cards throw `StateError: Bad state: No element` inside `build`, and a
/// test would read "no overflow" as green for the wrong reason.
///
/// The map is keyed by species id so a card that does `firstWhere` on
/// `plant.speciesId` actually finds its row. Three entries, one of which is a
/// long-name probe so the sweep's adversarial strings reach the species label
/// too.
///
/// This is also the SECOND of two seeds a sweep needs for `FiltersBar`: the bar
/// reads `syncSpeciesTypeListProvider` too, and a bare species map would still
/// leave the bar asserting "exactly one item with DropdownButton's value" for
/// the species type dropdown. So a sweep that mounts FiltersBar must ALSO seed
/// `syncSpeciesTypeListProvider` (a List<SpeciesType>) — that is the card's
/// own stub, not part of this shared seed.
final speciesMap = <SpeciesComplete>[
  SpeciesComplete.empty().copyWith(
    id: 'species-1',
    name: 'Basilique',
    speciesType: enums.SpeciesType.plantesAromatiques,
  ),
  SpeciesComplete.empty().copyWith(
    id: 'species-2',
    name: 'Tomate',
    speciesType: enums.SpeciesType.plantesFruitiRes,
  ),
  SpeciesComplete.empty().copyWith(
    id: 'species-3',
    name: 'Intrus long-name species probe',
    speciesType: enums.SpeciesType.plantesAromatiques,
  ),
];

/// The section map the vote cards read from `sectionListProvider` on mount.
///
/// The exempted card here (`ListListCard`) indexes this map by section and then
/// reads `sectionsStatsProvider`, so this seed is the FIRST of two: it makes
/// the first `firstWhere` succeed. The second provider (`sectionsStatsProvider`)
/// is still unstubbed, so mounting `ListListCard` from a sweep would STILL
/// throw — which is exactly why it stays in `notMountedExemptions` rather than
/// becoming a mounted entry.
///
/// The map is keyed by `SectionComplete` because that is the type
/// `sectionListProvider` uses (`NotifierProvider<SectionList, ...>` whose
/// `build()` keys the inner map by `SectionComplete`), and `ListListCard`
/// indexes it as `sectionsList[section]`.
///
/// `sectionListProvider` is a `NotifierProvider`, NOT a `ListNotifierAPI` — its
/// state is the whole map and there is no `AsyncValue<List<...>>` shape for it.
/// So this seed sets the map directly on the notifier rather than wrapping it in
/// `AsyncValue.data`.
final sectionMap = <SectionComplete, AsyncValue<List<ListReturn>>>{
  SectionComplete.empty().copyWith(
    id: 'section-1',
    name: 'Section 1',
  ): AsyncValue.data([
    ListReturn.empty().copyWith(id: 'list-1', name: 'Liste A'),
    ListReturn.empty().copyWith(id: 'list-2', name: 'Liste B'),
  ]),
};

/// The species-type list the `FiltersBar` reads from
/// `syncSpeciesTypeListProvider` on mount.
///
/// This is the SECOND of two seeds a sweep needs for `FiltersBar`: the bar reads
/// `syncSpeciesListProvider` (seeded by `speciesMap`) AND
/// `syncSpeciesTypeListProvider`. A sweep that mounts `FiltersBar` from the sweep
/// must seed BOTH — `speciesMap` via `seedSharedMaps` and this list via the card's
/// own stub (the card itself sets `syncSpeciesTypeListProvider.notifier.state` to a
/// `SpeciesTypesReturn`). This constant is the card-specific stub for the sweep:
/// it provides the dropdown's value list so the bar does not assert
/// "exactly one item with DropdownButton's value" for the species type dropdown.
final speciesTypeList = SpeciesTypesReturn(
  speciesType: const [
    enums.SpeciesType.plantesAromatiques,
    enums.SpeciesType.plantesFruitiRes,
  ],
);

/// Seeds the two shared provider maps a sweep (or any other test) needs to
/// mount seed-library and vote cards.
///
/// Call this in a sweep `setUp` when the sweep decides to mount a card that
/// reads `syncSpeciesListProvider` or `sectionListProvider` — otherwise the
/// card throws `Bad state: No element` inside `build` and the test reads "no
/// overflow" as green for the wrong reason.
///
/// This seeds the providers that the SIX `notMountedExemptions` cards read;
/// the cards themselves stay exempted because at least one further provider each
/// still needs stubbing (the `speciesTypeList` for FiltersBar, the
/// `sectionsStatsProvider` for ListListCard, the orders/associations maps for
/// OrderSection, etc.). Seeding here is a precondition, not a completion —
/// deleting an exemption requires its own card-specific stub in the sweep file.
///
/// A sweep that calls this will still fail to mount FiltersBar, PersonalPlantCard,
/// PlantCard, or ListListCard until it ALSO stubs the card-specific providers this
/// function does not touch: `speciesTypeList` for FiltersBar (the card sets/// `syncSpeciesTypeListProvider.notifier.state` to `speciesTypeList`), the/// `sectionsStatsProvider` for ListListCard (a `NotifierProvider<SectionComplete, int>`),
  /// and the species id on the plant fixtures for PersonalPlantCard/PlantCard.
/// `seedSharedMaps` only does the two maps shared by more than one card; every
/// further provider is the card's own.
void seedSharedMaps(ProviderContainer container) {
  container.read(speciesListProvider.notifier).state = AsyncValue.data(
    speciesMap,
  );
  // The sectionListProvider's state is the WHOLE map, not one entry. Pass
  // sectionMap as-is; it already has the one section a sweep needs. This is a
  // NotifierProvider whose build() keys the inner map by SectionComplete, so the
  // state must be a Map<SectionComplete, AsyncValue<List<ListReturn>>> —
  // exactly the shape of sectionMap.
  container.read(sectionListProvider.notifier).state = sectionMap;

  // `ListListCard` reads sectionsStatsProvider after the section map, so this
  // seed is only the FIRST of two for it; the card's own stub seeds the second.
  //
  // `OrderSection` reads the orders/associations maps, which are page-scoped
  // and not part of this seed — it stays in notMountedExemptions.
}
