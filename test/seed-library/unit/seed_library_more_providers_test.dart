import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/my_plants_list_provider.dart';
import 'package:titan/seed-library/providers/plant_complete_provider.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/seed-library/providers/propagation_method_provider.dart';
import 'package:titan/seed-library/tools/constants.dart';
import 'package:titan/seed-library/tools/functions.dart' as seed_functions;
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/mock_openapi.dart';

/// The small provider/function corners the integration flows don't reach:
/// the propagation setter, MyPlantList's local list surgery (and its
/// loading-state no-ops), loadPlant's success and failure arms, the
/// species-type sync fallback, and openLink's refusal message.
class _MyPlantsDataNotifier extends MyPlantListNotifier {
  _MyPlantsDataNotifier(this.plants);
  final List<PlantSimple> plants;

  @override
  AsyncValue<List<PlantSimple>> build() => AsyncValue.data(plants);
}

class _MyPlantsLoadingNotifier extends MyPlantListNotifier {
  @override
  AsyncValue<List<PlantSimple>> build() => const AsyncValue.loading();
}

PlantSimple plant(String id, {String? nickname}) => PlantSimple.empty()
    .copyWith(id: id, reference: id.toUpperCase(), nickname: nickname);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropagationMethodNotifier', () {
    test('defaults to graine and switches to bouture', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(propagationMethodProvider),
        PropagationMethod.graine,
      );
      container
          .read(propagationMethodProvider.notifier)
          .setPropagationMethod(PropagationMethod.bouture);
      expect(
        container.read(propagationMethodProvider),
        PropagationMethod.bouture,
      );
      expect(
        container.read(propagationMethodProvider.notifier),
        isA<PropagationMethodNotifier>(),
      );
    });
  });

  group('MyPlantListNotifier', () {
    test('add, update and delete move a data state', () {
      final container = ProviderContainer(
        overrides: [
          myPlantListProvider.overrideWith(
            () => _MyPlantsDataNotifier([plant('p1')]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(myPlantListProvider.notifier);

      notifier.addPlantToList(plant('p2', nickname: 'nouvelle'));
      expect(container.read(myPlantListProvider).value?.map((p) => p.id), [
        'p1',
        'p2',
      ]);

      notifier.updatePlantInList(plant('p1', nickname: 'renommée'));
      final list = container.read(myPlantListProvider).value!;
      expect(list.firstWhere((p) => p.id == 'p1').nickname, 'renommée');

      notifier.deletePlantFromList('p1');
      expect(container.read(myPlantListProvider).value?.map((p) => p.id), [
        'p2',
      ]);
    });

    test('the loading state absorbs every mutation', () {
      final container = ProviderContainer(
        overrides: [
          myPlantListProvider.overrideWith(_MyPlantsLoadingNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(myPlantListProvider.notifier);

      notifier.addPlantToList(plant('p1'));
      notifier.updatePlantInList(plant('p9'));
      notifier.deletePlantFromList('p1');

      expect(container.read(myPlantListProvider).isLoading, isTrue);
    });
  });

  group('PlantNotifier.loadPlant', () {
    late MockOpenapi mock;

    setUp(() => mock = MockOpenapi());

    test('a 200 lands the plant in a data state', () async {
      final detail = PlantComplete.empty().copyWith(
        id: 'p1',
        reference: 'BAS-0001',
        speciesId: 'sp-1',
      );
      when(() => mock.seedLibraryPlantsPlantIdGet(plantId: 'p1')).thenAnswer(
        (_) async => chopper.Response(http.Response('{}', 200), detail),
      );

      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      await container.read(plantProvider.notifier).loadPlant('p1');
      final state = container.read(plantProvider);
      expect(state.value?.id, 'p1');
      expect(state.hasError, isFalse);
    });

    test('a 400 surfaces as an AsyncError', () async {
      when(() => mock.seedLibraryPlantsPlantIdGet(plantId: 'p1')).thenAnswer(
        (_) async =>
            chopper.Response<PlantComplete>(http.Response('err', 400), null),
      );

      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      await container.read(plantProvider.notifier).loadPlant('p1');
      expect(container.read(plantProvider).hasError, isTrue);
    });
  });

  group('syncSpeciesTypeListProvider', () {
    test('falls back while loading and maps once the data lands', () async {
      final mock = MockOpenapi();
      final response = SpeciesTypesReturn(
        speciesType: [SpeciesType.plantesPotagRes],
      );
      var complete = false;
      when(() => mock.seedLibrarySpeciesTypesGet()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        complete = true;
        return chopper.Response(http.Response('{}', 200), response);
      });

      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      // First read starts the load: the sync projection answers the
      // loading input with the empty fallback.
      container.read(speciesTypeListProvider);
      expect(container.read(syncSpeciesTypeListProvider).speciesType, isEmpty);

      await pumpEventQueue();
      while (!complete) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(container.read(syncSpeciesTypeListProvider).speciesType, [
        SpeciesType.plantesPotagRes,
      ]);
    });
  });

  test('openLink quotes the message pair the platform refuses', () async {
    stubUrlLauncher(FakeUrlLauncher(launchSucceeds: false));

    Object? caught;
    runZonedGuarded(
      () => seed_functions.openLink('https://stuck.example'),
      (error, _) => caught = error,
    );
    await pumpEventQueue();

    expect(
      caught,
      '${SeedLibraryTextConstants.unableToOpen} https://stuck.example',
    );
  });
}
