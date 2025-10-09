import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/history.dart';
import 'package:titan/paiement/class/store.dart';
import 'package:titan/paiement/providers/selected_interval_provider.dart';
import 'package:titan/paiement/providers/selected_store_provider.dart';
import 'package:titan/paiement/repositories/stores_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class SellerHistoryNotifier extends ListNotifier<History> {
  StoresRepository get storesRepository => ref.watch(storesRepositoryProvider);

  @override
  AsyncValue<List<History>> build() {
    final selectedStore = ref.watch(selectedStoreProvider);
    final selectedInterval = ref.watch(selectedIntervalProvider);

    if (selectedStore.id != Store.empty().id) {
      getHistory(
        selectedStore.id,
        selectedInterval.start,
        selectedInterval.end,
      );
    }

    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<History>>> getHistory(
    String storeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await loadList(
      () => storesRepository.getStoreHistory(storeId, startDate, endDate),
    );
  }
}

final sellerHistoryProvider =
    NotifierProvider<SellerHistoryNotifier, AsyncValue<List<History>>>(
      SellerHistoryNotifier.new,
    );
