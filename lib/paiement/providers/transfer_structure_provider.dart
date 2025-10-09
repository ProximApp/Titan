import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/structure.dart';
import 'package:titan/paiement/repositories/structures_repository.dart';

class TransferStructureNotifier extends Notifier<AsyncValue> {
  StructuresRepository get structuresRepository =>
      ref.watch(structuresRepositoryProvider);

  @override
  AsyncValue build() {
    return const AsyncValue.loading();
  }

  Future<bool> initTransfer(Structure structure, String newUserId) async {
    return await structuresRepository.initializeManagerTransfer(
      structure,
      newUserId,
    );
  }
}

final transferStructureProvider =
    NotifierProvider<TransferStructureNotifier, AsyncValue>(
      TransferStructureNotifier.new,
    );
