import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/amap/class/delivery.dart';
import 'package:titan/amap/repositories/delivery_list_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class DeliveryListNotifier extends ListNotifier<Delivery> {
  DeliveryListRepository get deliveryListRepository =>
      ref.read(deliveryListRepositoryProvider);

  @override
  AsyncValue<List<Delivery>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Delivery>>> loadDeliveriesList() async {
    return await loadList(deliveryListRepository.getDeliveryList);
  }

  Future<bool> addDelivery(Delivery delivery) async {
    return await add(deliveryListRepository.createDelivery, delivery);
  }

  Future<bool> updateDelivery(Delivery delivery) async {
    return await update(
      deliveryListRepository.updateDelivery,
      (deliveries, delivery) =>
          deliveries
            ..[deliveries.indexWhere((d) => d.id == delivery.id)] = delivery,
      delivery,
    );
  }

  Future<bool> openDelivery(Delivery delivery) async {
    return await update(
      deliveryListRepository.openDelivery,
      (deliveries, delivery) => deliveries
        ..[deliveries.indexWhere((d) => d.id == delivery.id)] = delivery
            .copyWith(status: DeliveryStatus.available),
      delivery,
    );
  }

  Future<bool> lockDelivery(Delivery delivery) async {
    return await update(
      deliveryListRepository.lockDelivery,
      (deliveries, delivery) => deliveries
        ..[deliveries.indexWhere((d) => d.id == delivery.id)] = delivery
            .copyWith(status: DeliveryStatus.locked),
      delivery,
    );
  }

  Future<bool> deliverDelivery(Delivery delivery) async {
    return await update(
      deliveryListRepository.deliverDelivery,
      (deliveries, delivery) => deliveries
        ..[deliveries.indexWhere((d) => d.id == delivery.id)] = delivery
            .copyWith(status: DeliveryStatus.delivered),
      delivery,
    );
  }

  Future<bool> archiveDelivery(Delivery delivery) async {
    return await delete(
      deliveryListRepository.archiveDelivery,
      (deliveries, delivery) =>
          deliveries..removeWhere((i) => i.id == delivery.id),
      delivery.id,
      delivery,
    );
  }

  Future<bool> deleteDelivery(Delivery delivery) async {
    return await delete(
      deliveryListRepository.deleteDelivery,
      (deliveries, delivery) =>
          deliveries..removeWhere((i) => i.id == delivery.id),
      delivery.id,
      delivery,
    );
  }

  void toggleExpanded(String deliveryId) {
    state.when(
      data: (deliveries) {
        var index = deliveries.indexWhere((p) => p.id == deliveryId);
        if (index == -1) return;
        deliveries[index] = deliveries[index].copyWith(
          expanded: !deliveries[index].expanded,
        );
        state = AsyncValue.data(deliveries);
      },
      error: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
      loading: () {
        state = const AsyncValue.error(
          "Cannot toggle expanded while loading",
          StackTrace.empty,
        );
      },
    );
  }

  Future<List<Delivery>> copy() async {
    return state.maybeWhen(
      data: (deliveries) => List.from(deliveries),
      orElse: () => [],
    );
  }
}

final deliveryListProvider =
    NotifierProvider<DeliveryListNotifier, AsyncValue<List<Delivery>>>(
      DeliveryListNotifier.new,
    );

final deliveryList = Provider<List<Delivery>>((ref) {
  final state = ref.watch(deliveryListProvider);
  return state.maybeWhen(data: (deliveries) => deliveries, orElse: () => []);
});
