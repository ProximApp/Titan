import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/seed-library/class/species_type.dart';
import 'package:titan/seed-library/repositories/species_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class SpeciesListNotifier extends ListNotifier<SpeciesType> {
  late final SpeciesRepository speciesRepository;

  @override
  AsyncValue<List<SpeciesType>> build() {
    speciesRepository = ref.watch(speciesRepositoryProvider);
    tokenExpireWrapperAuth(ref, () async {
      await loadSpeciesTypes();
    });
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<SpeciesType>>> loadSpeciesTypes() async {
    return await loadList(speciesRepository.getSpeciesTypeList);
  }
}

final speciesTypeListProvider =
    NotifierProvider<SpeciesListNotifier, AsyncValue<List<SpeciesType>>>(
      SpeciesListNotifier.new,
    );

final syncSpeciesTypeListProvider = Provider<List<SpeciesType>>((ref) {
  final speciesList = ref.watch(speciesTypeListProvider);
  return speciesList.maybeWhen(
    orElse: () => [],
    data: (speciesType) => speciesType,
  );
});
