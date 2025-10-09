import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/class/assocation.dart';
import 'package:titan/admin/repositories/association_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class MyAssociationListNotifier extends ListNotifier<Association> {
  AssociationRepository get associationRepository =>
      ref.watch(associationRepositoryProvider);

  @override
  AsyncValue<List<Association>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Association>>> loadAssociations() async {
    return await loadList(associationRepository.getMyAssociations);
  }
}

final asyncMyAssociationListProvider =
    NotifierProvider<MyAssociationListNotifier, AsyncValue<List<Association>>>(
      () => MyAssociationListNotifier(),
    );

final myAssociationListProvider = Provider<List<Association>>((ref) {
  final asyncMyAssociationList = ref.watch(asyncMyAssociationListProvider);
  return asyncMyAssociationList.maybeWhen(
    data: (associations) => associations,
    orElse: () => [],
  );
});
