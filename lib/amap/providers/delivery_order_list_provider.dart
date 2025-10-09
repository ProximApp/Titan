import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/amap/class/order.dart';
import 'package:titan/tools/providers/map_provider.dart';

class AdminDeliveryOrderListNotifier extends MapNotifier<String, Order> {}

final adminDeliveryOrderListProvider =
    NotifierProvider<
      AdminDeliveryOrderListNotifier,
      Map<String, AsyncValue<List<Order>>?>
    >(() => AdminDeliveryOrderListNotifier());
