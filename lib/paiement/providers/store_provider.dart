import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/paiement/class/store.dart';

class StoreProvider extends Notifier<Store> {
  @override
  Store build() {
    return Store.empty();
  }

  void updateStore(Store store) {
    state = store;
  }
}

final storeProvider = NotifierProvider<StoreProvider, Store>(StoreProvider.new);
