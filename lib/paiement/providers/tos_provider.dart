import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/tos.dart';
import 'package:titan/paiement/repositories/tos_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class TOSNotifier extends SingleNotifier<TOS> {
  TosRepository get tosRepository => ref.watch(tosRepositoryProvider);

  @override
  AsyncValue<TOS> build() {
    getTOS();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<TOS>> getTOS() async {
    return await load(tosRepository.getTOS);
  }

  Future<bool> signTOS(TOS tos) async {
    return await update(tosRepository.signTOS, tos);
  }
}

final tosProvider = NotifierProvider<TOSNotifier, AsyncValue<TOS>>(
  TOSNotifier.new,
);
