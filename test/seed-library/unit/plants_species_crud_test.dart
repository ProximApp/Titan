import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/seed-library/providers/plants_list_provider.dart';
import 'package:titan/seed-library/providers/species_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  group('SpeciesListNotifier', () {
    setUp(() {
      when(() => repo.seedLibrarySpeciesGet())
          .thenAnswer((_) async => repo.okList<SpeciesComplete>());
    });

    test('loadSpecies resolves an empty waiting list', () async {
      final notifier = container.read(speciesListProvider.notifier);
      final state = await notifier.loadSpecies();
      expect(state.value, isEmpty);
    });

    test('createSpecies posts a SpeciesBase and appends the answer', () async {
      final notifier = container.read(speciesListProvider.notifier);
      await notifier.loadSpecies();
      final species = SpeciesComplete.empty().copyWith(
        id: 'sp-1',
        name: 'Tomate',
        prefix: 'TOM',
      );
      notifier.state = AsyncValue.data([]);
      when(() => repo.seedLibrarySpeciesPost(body: any(named: 'body')))
          .thenAnswer((_) async => repo.ok(species));

      final ok = await notifier.createSpecies(species);
      expect(ok, isTrue);
      expect(notifier.state.value!.single.name, 'Tomate');
    });

    test('updateSpecies success swaps the species in the list', () async {
      final notifier = container.read(speciesListProvider.notifier);
      await notifier.loadSpecies();
      final species = SpeciesComplete.empty().copyWith(
        id: 'sp-1',
        name: 'Tomate',
      );
      notifier.state = AsyncValue.data([species]);
      when(
        () => repo.seedLibrarySpeciesSpeciesIdPatch(
          speciesId: 'sp-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.updateSpecies(
        species.copyWith(name: 'Poivron'),
      );
      expect(ok, isTrue);
      expect(notifier.state.value!.single.name, 'Poivron');
    });

    test('updateSpecies failure keeps the previous species', () async {
      final notifier = container.read(speciesListProvider.notifier);
      await notifier.loadSpecies();
      final species = SpeciesComplete.empty().copyWith(
        id: 'sp-1',
        name: 'Tomate',
      );
      notifier.state = AsyncValue.data([species]);
      when(
        () => repo.seedLibrarySpeciesSpeciesIdPatch(
          speciesId: 'sp-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.fail<void>(400));

      final ok = await notifier.updateSpecies(species);
      expect(ok, isFalse);
      expect(notifier.state.value!.single.name, 'Tomate');
    });

    test('deleteSpecie success removes the species', () async {
      final notifier = container.read(speciesListProvider.notifier);
      await notifier.loadSpecies();
      final species = SpeciesComplete.empty().copyWith(id: 'sp-1');
      notifier.state = AsyncValue.data([species]);
      when(() => repo.seedLibrarySpeciesSpeciesIdDelete(speciesId: 'sp-1'))
          .thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deleteSpecie(species);
      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });

    test('deleteSpecie failure keeps the species', () async {
      final notifier = container.read(speciesListProvider.notifier);
      await notifier.loadSpecies();
      final species = SpeciesComplete.empty().copyWith(id: 'sp-1');
      notifier.state = AsyncValue.data([species]);
      when(() => repo.seedLibrarySpeciesSpeciesIdDelete(speciesId: 'sp-1'))
          .thenAnswer((_) async => repo.fail<void>(404));

      final ok = await notifier.deleteSpecie(species);
      expect(ok, isFalse);
      expect(notifier.state.value, hasLength(1));
    });
  });

  group('PlantListNotifier', () {
    setUp(() {
      when(() => repo.seedLibraryPlantsWaitingGet())
          .thenAnswer((_) async => repo.okList<PlantSimple>());
    });

    test('loadPlants resolves an empty waiting list', () async {
      final notifier = container.read(plantListProvider.notifier);
      final state = await notifier.loadPlants();
      expect(state.value, isEmpty);
    });

    test('createPlant posts and appends the new plant', () async {
      final notifier = container.read(plantListProvider.notifier);
      await notifier.loadPlants();
      final creation = PlantCreation.empty().copyWith(speciesId: 'sp-1');
      final created = PlantSimple.empty().copyWith(
        id: 'pl-1',
        reference: 'NEW',
      );
      notifier.state = AsyncValue.data([]);
      when(() => repo.seedLibraryPlantsPost(body: any(named: 'body')))
          .thenAnswer((_) async => repo.ok(created));

      final ok = await notifier.createPlant(creation);
      expect(ok, isTrue);
      expect(notifier.state.value!.single.reference, 'NEW');
    });

    test('createPlant failure leaves the list untouched', () async {
      final notifier = container.read(plantListProvider.notifier);
      await notifier.loadPlants();
      final creation = PlantCreation.empty();
      notifier.state = AsyncValue.data([]);
      when(() => repo.seedLibraryPlantsPost(body: any(named: 'body')))
          .thenAnswer((_) async => repo.fail<PlantSimple>(400));

      final ok = await notifier.createPlant(creation);
      expect(ok, isFalse);
      expect(notifier.state.value, isEmpty);
    });

    test('deletePlant success removes the plant', () async {
      final notifier = container.read(plantListProvider.notifier);
      await notifier.loadPlants();
      final plant = PlantSimple.empty().copyWith(id: 'pl-1');
      notifier.state = AsyncValue.data([plant]);
      when(() => repo.seedLibraryPlantsPlantIdDelete(plantId: 'pl-1'))
          .thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deletePlant(plant);
      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });

    test('deletePlant failure keeps the plant', () async {
      final notifier = container.read(plantListProvider.notifier);
      await notifier.loadPlants();
      final plant = PlantSimple.empty().copyWith(id: 'pl-1');
      notifier.state = AsyncValue.data([plant]);
      when(() => repo.seedLibraryPlantsPlantIdDelete(plantId: 'pl-1'))
          .thenAnswer((_) async => repo.fail<void>(404));

      final ok = await notifier.deletePlant(plant);
      expect(ok, isFalse);
      expect(notifier.state.value, hasLength(1));
    });

    test(
      'the in-place list editors rebuild a fresh list on data only',
      () async {
        final notifier = container.read(plantListProvider.notifier);
        await notifier.loadPlants();
        final plantA = PlantSimple.empty().copyWith(id: 'pl-1', reference: 'A');
        final plantB = PlantSimple.empty().copyWith(id: 'pl-2', reference: 'B');
        notifier.state = AsyncValue.data([plantA]);

        notifier.addPlantToList(plantB);
        expect(notifier.state.value!.map((p) => p.id), ['pl-1', 'pl-2']);

        notifier.updatePlantInList(plantA.copyWith(reference: 'A2'));
        expect(notifier.state.value!.first.reference, 'A2');

        notifier.deletePlantFromList('pl-2');
        expect(notifier.state.value!.map((p) => p.id), ['pl-1']);

        // Non-data states are a no-op through the orElse branch.
        final boom = AsyncValue<List<PlantSimple>>.error(
          'boom',
          StackTrace.empty,
        );
        notifier.state = boom;
        notifier.addPlantToList(plantB);
        notifier.updatePlantInList(plantA);
        notifier.deletePlantFromList('pl-1');
        expect(notifier.state, same(boom));
      },
    );
  });
}
