import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/user_store.dart';
import 'package:titan/paiement/repositories/users_me_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class MyStoresNotifier extends ListNotifier<UserStore> {
  UsersMeRepository get usersMeRepository =>
      ref.watch(usersMeRepositoryProvider);

  @override
  AsyncValue<List<UserStore>> build() {
    getMyStores();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<UserStore>>> getMyStores() async {
    return await loadList(usersMeRepository.getMyStores);
  }
}

final myStoresProvider =
    NotifierProvider<MyStoresNotifier, AsyncValue<List<UserStore>>>(
      MyStoresNotifier.new,
    );
