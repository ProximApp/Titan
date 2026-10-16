import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/amap/providers/delivery_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/map_provider.dart';

class AdminDeliveryOrderListNotifier extends MapNotifier<String, OrderReturn> {
  @override
  Map<String, AsyncValue<List<OrderReturn>>?> build() {
    final deliveries = ref.watch(deliveryList);
    return {for (final delivery in deliveries) delivery.id: null};
  }
}

final adminDeliveryOrderListProvider =
    NotifierProvider<
      AdminDeliveryOrderListNotifier,
      Map<String, AsyncValue<List<OrderReturn>>?>
    >(() => AdminDeliveryOrderListNotifier());
