import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/ph/class/ph.dart';
import 'package:titan/ph/repositories/ph_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class PhListNotifier extends ListNotifier<Ph> {
  PhRepository get phRepository => ref.watch(phRepositoryProvider);

  @override
  AsyncValue<List<Ph>> build() {
    loadPhList();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Ph>>> loadPhList() async {
    return await loadList(() async => phRepository.getAllPh());
  }

  Future<bool> addPh(Ph ph) async {
    return await add(phRepository.addPh, ph);
  }

  Future<bool> editPh(Ph ph) async {
    return await update(
      phRepository.editPh,
      (phs, ph) =>
          phs..[phs.indexWhere((phToCheck) => phToCheck.id == ph.id)] = ph,
      ph,
    );
  }

  Future<bool> deletePh(Ph ph) async {
    return await delete(
      phRepository.deletePh,
      (phs, ph) => phs..removeWhere((phToCheck) => phToCheck.id == ph.id),
      ph.id,
      ph,
    );
  }
}

final phListProvider = NotifierProvider<PhListNotifier, AsyncValue<List<Ph>>>(
  PhListNotifier.new,
);
