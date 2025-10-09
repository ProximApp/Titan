import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/history.dart';
import 'package:titan/paiement/repositories/users_me_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class MyHistoryNotifier extends ListNotifier<History> {
  UsersMeRepository get usersMeRepository =>
      ref.watch(usersMeRepositoryProvider);

  @override
  AsyncValue<List<History>> build() {
    getHistory();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<History>>> getHistory() async {
    return await loadList(usersMeRepository.getMyHistory);
  }
}

final myHistoryProvider =
    NotifierProvider<MyHistoryNotifier, AsyncValue<List<History>>>(
      MyHistoryNotifier.new,
    );
