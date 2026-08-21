import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class PlantListNotifier extends ListNotifierAPI<PlantSimple> {
  Openapi get plantsRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<PlantSimple>> build() {
    loadPlants();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<PlantSimple>>> loadPlants() async {
    return await loadList(plantsRepository.seedLibraryPlantsWaitingGet);
  }

  Future<bool> createPlant(PlantCreation plant) async {
    return await add(
      () => plantsRepository.seedLibraryPlantsPost(body: plant),
      plant,
    );
  }

  Future<bool> deletePlant(PlantSimple plant) async {
    return await delete(
      () => plantsRepository.seedLibraryPlantsPlantIdDelete(plantId: plant.id),
      (plant) => plant.id,
      plant.id,
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

final plantListProvider =
    NotifierProvider<PlantListNotifier, AsyncValue<List<PlantSimple>>>(
      PlantListNotifier.new,
    );

final syncPlantListProvider = Provider<List<PlantSimple>>((ref) {
  final plantList = ref.watch(plantListProvider);
  return plantList.maybeWhen(orElse: () => [], data: (plants) => plants);
});
