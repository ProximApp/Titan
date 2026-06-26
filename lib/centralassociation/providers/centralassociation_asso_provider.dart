import 'package:titan/centralassociation/class/asso.dart';
import 'package:titan/centralassociation/class/link.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/centralassociation/repositories/asso_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

final assoRepositoryProvider = Provider<AssoRepository>(
  (ref) => AssoRepository(),
);

class AssoNotifier extends ListNotifier<Asso> {
  AssoRepository get assoRepository => ref.watch(assoRepositoryProvider);

  List<Asso> allAssos = [];
  List<Link> allLinks = [];

  @override
  AsyncValue<List<Asso>> build() {
    initState();
    return const AsyncValue.loading();
  }

  Future<void> initState() async {
    try {
      allAssos = await assoRepository.getAssoList();
      allLinks = allAssos.expand((element) => element.linkList).toList();
      state = AsyncValue.data(allAssos);
    } catch (e) {
      // Never leave the provider stuck in loading: surface the error instead.
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final assoProvider = NotifierProvider<AssoNotifier, AsyncValue<List<Asso>>>(
  AssoNotifier.new,
);
