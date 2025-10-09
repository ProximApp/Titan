import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/amap/class/order.dart';

class OrderNotifier extends Notifier<Order> {
  @override
  Order build() {
    return Order.empty();
  }

  void setOrder(Order order) {
    state = order;
  }
}

final orderProvider = NotifierProvider<OrderNotifier, Order>(OrderNotifier.new);
