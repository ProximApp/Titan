import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/seed-library/providers/consumed_filter_provider.dart';
import 'package:titan/seed-library/providers/my_plants_list_provider.dart';
import 'package:titan/seed-library/providers/plants_filtered_list_provider.dart';
import 'package:titan/seed-library/providers/species_list_provider.dart';
import 'package:titan/seed-library/providers/string_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/tools/logs/print_logger_output.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';

/// Unit coverage for the seed-library filter chain: the pure
/// season→months mapper, `filterSpeciesWithFilters` (search, season,
/// difficulty, type) and the two filtered-list providers that chain the
/// filter notifiers with the plant lists (diacritic-insensitive search,
/// consumed-plant filtering, reference sorting).
SpeciesComplete species(
  String id, {
  String name = 'Monstera',
  int difficulty = 0,
  enums.SpeciesType type = enums.SpeciesType.autre,
  DateTime? startSeason,
}) => SpeciesComplete.empty().copyWith(
  id: id,
  name: name,
  difficulty: difficulty,
  speciesType: type,
  startSeason: startSeason,
);

PlantSimple plant(
  String reference,
  String speciesId, {
  enums.PlantState? state,
}) => PlantSimple.empty().copyWith(
  id: 'p-$reference',
  reference: reference,
  speciesId: speciesId,
  state: state ?? enums.PlantState.enAttente,
);

class _StubLogger extends Logger {
  _StubLogger() {
    loggerOutput = PrintLoggerOutput();
  }

  @override
  Future<void> init() async {}
}

void main() {
  // The list notifiers' build reads the repository (whose interceptors
  // touch the logger chain), so the binding and a stubbed logger are
  // required before any container is created.
  TestWidgetsFlutterBinding.ensureInitialized();

  // The list notifiers fire their GET on build; stubbing the endpoints
  // keeps the container's pending loads from exploding after the test ends.
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    when(() => scaffold.repository.seedLibrarySpeciesGet()).thenAnswer(
      (_) async => chopperListResponse<SpeciesComplete>(<SpeciesComplete>[]),
    );
    when(() => scaffold.repository.seedLibraryPlantsUsersMeGet()).thenAnswer(
      (_) async => chopperListResponse<PlantSimple>(<PlantSimple>[]),
    );
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      loggerProvider.overrideWith((ref) => _StubLogger()),
      repositoryProvider.overrideWithValue(scaffold.repository),
    ],
  );

  group('getMonthsBySeason', () {
    test('maps each season to its three months', () {
      expect(getMonthsBySeason(SeedLibraryTextConstants.spring), [4, 5, 6]);
      expect(getMonthsBySeason(SeedLibraryTextConstants.summer), [7, 8, 9]);
      expect(getMonthsBySeason(SeedLibraryTextConstants.autumn), [10, 11, 12]);
      expect(getMonthsBySeason(SeedLibraryTextConstants.winter), [1, 2, 3]);
    });

    test('unknown season keeps every month', () {
      expect(getMonthsBySeason('nonsense'), hasLength(12));
    });
  });

  group('filterSpeciesWithFilters', () {
    final list = [
      species('s1', name: 'Monstera deliciosa', difficulty: 2),
      species('s2', name: 'Basile commune', difficulty: 1),
      species('s3', name: 'Ficus', difficulty: 3),
    ];

    test('matches search diacritic-insensitively', () {
      expect(
        filterSpeciesWithFilters(
          list,
          'basile',
          SeedLibraryTextConstants.all,
          0,
          enums.SpeciesType.autre,
        ).map((s) => s.id),
        ['s2'],
      );
      // Accents in the query do not break the match.
      expect(
        filterSpeciesWithFilters(
          list,
          'basîle',
          SeedLibraryTextConstants.all,
          0,
          enums.SpeciesType.autre,
        ).map((s) => s.id),
        ['s2'],
      );
    });

    test('season filter passes species without a start season', () {
      final dated = [
        species('spring', startSeason: DateTime(2026, 4, 1)),
        species('never', startSeason: null),
      ];
      expect(
        filterSpeciesWithFilters(
          dated,
          '',
          SeedLibraryTextConstants.spring,
          0,
          enums.SpeciesType.autre,
        ).map((s) => s.id),
        ['spring', 'never'],
      );
    });

    test('difficulty 0 means no filter', () {
      expect(
        filterSpeciesWithFilters(
          list,
          '',
          SeedLibraryTextConstants.all,
          0,
          enums.SpeciesType.autre,
        ),
        hasLength(3),
      );
      expect(
        filterSpeciesWithFilters(
          list,
          '',
          SeedLibraryTextConstants.all,
          2,
          enums.SpeciesType.autre,
        ).map((s) => s.id),
        ['s1'],
      );
    });

    test('species type filter passes the "autre" catch-all', () {
      final typed = [
        species('aromatic', type: enums.SpeciesType.plantesAromatiques),
        species('other', type: enums.SpeciesType.autre),
      ];
      expect(
        filterSpeciesWithFilters(
          typed,
          '',
          SeedLibraryTextConstants.all,
          0,
          enums.SpeciesType.plantesAromatiques,
        ).map((s) => s.id),
        ['aromatic'],
      );
      expect(
        filterSpeciesWithFilters(
          typed,
          '',
          SeedLibraryTextConstants.all,
          0,
          enums.SpeciesType.autre,
        ),
        hasLength(2),
      );
    });
  });

  group('myPlantsFilteredListProvider', () {
    test(
      'filters by species, drops consumed plants, sorts by reference',
      () async {
        // Only the 'keep' species exists in the catalog: plants of other
        // species must disappear from the merged view.
        final speciesData = [species('keep')];
        final plants = [
          plant('ZZ', 'keep'),
          plant('aa', 'keep', state: enums.PlantState.consommE),
          plant('AB', 'keep'),
          plant('XX', 'drop'),
        ];
        final container = makeContainer();
        addTearDown(container.dispose);
        container.read(myPlantListProvider.notifier).state = AsyncValue.data(
          plants,
        );
        container.read(speciesListProvider.notifier).state = AsyncValue.data(
          speciesData,
        );

        // Consumed plants are hidden by default; aa < AB < ZZ would be the
        // case-sensitive sort without the filter.
        expect(
          container.read(myPlantsFilteredListProvider).map((p) => p.reference),
          ['AB', 'ZZ'],
        );

        // Showing consumed plants brings 'aa' back, still sorted (Dart's
        // string comparison puts uppercase before lowercase).
        container.read(consumedFilterProvider.notifier).setBool(true);
        expect(
          container.read(myPlantsFilteredListProvider).map((p) => p.reference),
          ['AB', 'ZZ', 'aa'],
        );
      },
    );

    test('search + species filters compose', () async {
      final speciesData = [
        species('m', name: 'Monstera'),
        species('b', name: 'Basile'),
      ];
      final plants = [plant('1', 'm'), plant('2', 'b')];
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(myPlantListProvider.notifier).state = AsyncValue.data(
        plants,
      );
      container.read(speciesListProvider.notifier).state = AsyncValue.data(
        speciesData,
      );
      container.read(searchFilterProvider.notifier).setString('monstera');

      expect(
        container.read(myPlantsFilteredListProvider).map((p) => p.reference),
        ['1'],
      );
    });
  });
}
