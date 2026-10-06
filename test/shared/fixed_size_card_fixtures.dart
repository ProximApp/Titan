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
/// The registry side of that accounting is strict:
/// `mounted_but_exempted_ratchet_test.dart` fails when a widget is BOTH in
/// `cardFixtures` (which every ratchet counts as "mounted") AND here (which
/// suppresses the mount at runtime). That overlap is the `ModuleCard` lie —
/// it sat exempt for several rounds with `module_card.dart` at 37/37
/// uncovered and the sweep green, because its stated reason ("needs the
/// modules map seeded") was simply false: `favoritesNameProvider` returns
/// `[]`, so the card needed nothing, and what it actually needed was a
/// bounded parent (its `Column` holds an `Expanded`, which asserts under the
/// sweep's unbounded scroll view). The exemption was deleted rather than
/// satisfied; the card is really mounted via its `wrap` parent and at widget
/// level in `test/centralisation/widget/centralisation_cards_widget_test.dart`.
///
/// Four more exemptions followed it out once the fixtures grew their own
/// stubs (`FiltersBar`, `PersonalPlantCard`, `PlantCard`, `ListListCard` —
/// seeds in `seedSharedMaps`, card-specific stubs inline in each fixture).
/// What remains is `OrderSection`, whose orders/associations maps are
/// page-scoped: un-exempting it needs those maps seeded, and until then it
/// is accounted here and absent from `cardFixtures` — the ratchet keeps
/// those two facts from drifting apart. Treat a reason in this map as
/// unverified until some test mounts the card.
///
/// This is the SAME list both sweeps read from; never duplicate it.
const notMountedExemptions = <String, String>{
  /// `OrderSection` reads the amap orders/associations maps, which are
  /// page-scoped and not part of the shared seed — it stays exempted.
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
////// This seeds the providers the shared exemption used to need — the species
/// map for the seed-library cards, the section map for the vote card. Four
/// exemptions were deleted once each fixture grew its OWN inline stub on top
/// of these seeds (`FiltersBar` stubs `syncSpeciesTypeListProvider`,
/// `ListListCard` stubs `statusProvider` + `sectionsStatsProvider`, the plant
/// fixtures carry a species id that resolves against `speciesMap`), so the
/// sweeps that mount those cards MUST call this before building them.
///
/// `OrderSection` is the one card still in `notMountedExemptions`: it reads
/// the orders/associations maps, which are page-scoped and not part of this
/// seed, so seeding here does not un-exempt it.
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

/// The candidates the CardLayout MOUNT RATCHET exempts, each with the
/// reason it cannot be mounted by a widget test.
///
/// A page is rendered by its module's integration test, not by a widget
/// test, so the page-shaped entries below are not debt — they are the
/// boundary between the two levels. The technical entries (amap's
/// sections, dialogs and detail card; loan's two admin sections) claim
/// they CANNOT mount without page-level provider state.
///
/// This lives here — not inside `fixed_size_card_layouts_test.dart` — so
/// `test/tools/unit/exemption_mount_audit_test.dart` can attempt a real
/// mount of every entry and hold each claim to the outcome: technical
/// entries must fail with their documented error, level-boundary entries
/// must have their integration target present. A mount that succeeds
/// under a technical reason is a stale exemption, and the audit fails.
/// This is the SAME list the ratchet reads from; never duplicate it.
const cardLayoutNotMountedExemptions = <String, String>{
  'lib/amap/ui/pages/main_page/orders_section.dart OrderSection':
      'renders the amap orders list, which needs the orders/associations '
      'provider maps seeded; a bare OrderSection throws ProviderException. '
      'Also exempted by the fixed-width sweep for the same reason.',
  'lib/amap/ui/pages/detail_delivery_page/order_detail_ui.dart DetailOrderUI':
      'BLOCKED by bug #3: its build watches userOrderListProvider, whose '
      'notifier `return state` from build(), which throws "Tried to read the '
      'state of an uninitialized provider" through Riverpod\'s provider '
      'error channel — a channel the FlutterError.onError filter in '
      'ignoreAmapKnownQuirks() cannot absorb, so the card never lays out. '
      'The one-line fix is `return const AsyncValue.loading()` in '
      'user_order_list_provider.dart, which is what every other '
      'ListNotifierAPI subclass already does.',
  'lib/amap/ui/pages/admin_page/account_handler.dart AccountHandler':
      'an admin edit DIALOG opened by the accounts page, not a card: it '
      'needs the accounts provider map and a route to dismiss back to.',
  'lib/amap/ui/pages/admin_page/delivery_handler.dart DeliveryHandler':
      'an admin edit DIALOG opened by the deliveries page, same reason as '
      'AccountHandler.',
  'lib/amap/ui/pages/admin_page/product_handler.dart ProductHandler':
      'an admin edit DIALOG opened by the products page, same reason as '
      'AccountHandler.',
  'lib/loan/ui/pages/admin_page/loaners_items.dart LoanersItems':
      'a list SECTION of the admin page, not a card: it composes '
      'CheckItemCard rows out of the admin loan list and needs that map '
      'seeded. Its own leaf is mounted by the sweep.',
  'lib/loan/ui/pages/admin_page/on_going_loan.dart OnGoingLoan':
      'a list SECTION of the admin page, same reason as LoanersItems.',
  'lib/purchases/ui/pages/scan_page/scan_dialog.dart ScanDialog':
      'a MODAL, covered end-to-end by '
      'purchases/integration/purchases_scan_integration_test.dart (tag to '
      'scan to confirm, with the stale-secret probe). A widget test could '
      'mount it, but the page it navigates to is what makes it worth '
      'testing, and that is the integration level\'s job.',
  'lib/booking/ui/pages/main_page/main_page.dart BookingMainPage':
      'a PAGE. Rendered by booking\'s integration tests.',
  'lib/cinema/ui/pages/admin_page/admin_page.dart AdminPage':
      'a PAGE. Rendered by cinema\'s integration tests.',
  'lib/event/ui/pages/main_page/main_page.dart EventMainPage':
      'a PAGE. Rendered by event/feed\'s integration tests.',
  'lib/seed-library/ui/pages/species_page/species_page.dart SpeciesPage':
      'a PAGE. Rendered by seed-library\'s integration tests.',
};
