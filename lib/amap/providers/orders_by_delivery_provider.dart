import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/amap/class/order.dart';
import 'package:titan/amap/repositories/order_list_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class OrderByDeliveryListNotifier extends ListNotifier<Order> {
  OrderListRepository get orderListRepository =>
      ref.watch(orderListRepositoryProvider);

  @override
  AsyncValue<List<Order>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Order>>> loadDeliveryOrderList(
    String deliveryId,
  ) async {
    return await loadList(
      () async => orderListRepository.getDeliveryOrderList(deliveryId),
    );
  }
}

final orderByDeliveryListProvider =
    NotifierProvider<OrderByDeliveryListNotifier, AsyncValue<List<Order>>>(
      () => OrderByDeliveryListNotifier(),
    );
