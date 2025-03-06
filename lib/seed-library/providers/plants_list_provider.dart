import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/seed-library/class/plant_creation.dart';
import 'package:titan/seed-library/class/plant_simple.dart';
import 'package:titan/seed-library/repositories/plants_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class PlantListNotifier extends ListNotifier<PlantSimple> {
  late final PlantsRepository plantsRepository;

  @override
  AsyncValue<List<PlantSimple>> build() {
    plantsRepository = ref.watch(plantsRepositoryProvider);
    loadPlants();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<PlantSimple>>> loadPlants() async {
    return await loadList(plantsRepository.getPlantSimplelist);
  }

  Future<AsyncValue<List<PlantSimple>>> loadMyPlants() async {
    return await loadList(plantsRepository.getMyPlantSimple);
  }

  Future<bool> createPlant(PlantCreation plant) async {
    return await add(
      (plantSimple) => plantsRepository.createPlants(plant),
      PlantSimple.empty(),
    );
  }

  Future<bool> deletePlant(PlantSimple plant) async {
    return await delete(
      plantsRepository.deletePlants,
      (plants, plant) => plants..removeWhere((i) => i.id == plant.id),
      plant.id,
      plant,
    );
  }

  void deletePlantFromList(String id) {
    state = state.maybeWhen(
      orElse: () => state,
      data: (plants) => AsyncValue.data(plants..removeWhere((i) => i.id == id)),
    );
  }

  void addPlantToList(PlantSimple plant) {
    state = state.maybeWhen(
      orElse: () => state,
      data: (plants) => AsyncValue.data([...plants, plant]),
    );
  }

  void updatePlantInList(PlantSimple plant) {
    state = state.maybeWhen(
      orElse: () => state,
      data: (plants) => AsyncValue.data(
        plants.map((i) => i.id == plant.id ? plant : i).toList(),
      ),
    );
  }
}

class MyPlantListNotifier extends ListNotifier<PlantSimple> {
  late final PlantsRepository plantsRepository;

  @override
  AsyncValue<List<PlantSimple>> build() {
      plantsRepository = ref.watch(plantsRepositoryProvider);
       loadMyPlants();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<PlantSimple>>> loadMyPlants() async {
    return await loadList(plantsRepository.getMyPlantSimple);
  }

  void deletePlantFromList(String id) {
    state = state.maybeWhen(
      orElse: () => state,
      data: (plants) => AsyncValue.data(plants..removeWhere((i) => i.id == id)),
    );
  }

  void addPlantToList(PlantSimple plant) {
    state = state.maybeWhen(
      orElse: () => state,
      data: (plants) => AsyncValue.data(plants..add(plant)),
    );
  }

  void updatePlantInList(PlantSimple plant) {
    state = state.maybeWhen(
      orElse: () => state,
      data: (plants) => AsyncValue.data(
        plants.map((i) => i.id == plant.id ? plant : i).toList(),
      ),
    );
  }
}

final plantListProvider =
    NotifierProvider<PlantListNotifier, AsyncValue<List<PlantSimple>>>(
      PlantListNotifier.new,
    );

final syncPlantListProvider = Provider<List<PlantSimple>>((ref) {
  final plantList = ref.watch(plantListProvider);
  return plantList.maybeWhen(orElse: () => [], data: (plants) => plants);
});

final myPlantListProvider =
    NotifierProvider<MyPlantListNotifier, AsyncValue<List<PlantSimple>>>(
      MyPlantListNotifier.new,
    );

final syncMyPlantListProvider = Provider<List<PlantSimple>>((ref) {
  final plantList = ref.watch(myPlantListProvider);
  return plantList.maybeWhen(orElse: () => [], data: (plants) => plants);
});
