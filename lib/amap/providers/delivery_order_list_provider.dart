import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/amap/providers/delivery_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/providers/map_provider.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class AdminDeliveryOrderListNotifier extends MapNotifier<String, OrderReturn> {
  @override
  Map<String, AsyncValue<List<OrderReturn>>?> build() {
    tokenExpireWrapperAuth(ref, () async {
      final deliveries = ref.watch(deliveryList);
      loadTList(deliveries.map((e) => e.id).toList());
    });
    return const {};
  }
}

final adminDeliveryOrderListProvider =
    NotifierProvider<
      AdminDeliveryOrderListNotifier,
      Map<String, AsyncValue<List<OrderReturn>>?>
    >(() => AdminDeliveryOrderListNotifier());
