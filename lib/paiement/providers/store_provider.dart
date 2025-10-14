import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class StoreProvider extends Notifier<UserStore> {
  @override
  UserStore build() {
    return EmptyModels.empty<UserStore>();
  }

  void updateStore(UserStore store) {
    state = store;
  }
}

final storeProvider = NotifierProvider<StoreProvider, UserStore>(StoreProvider.new);
