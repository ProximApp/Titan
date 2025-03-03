import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class OrderNotifier extends Notifier<OrderReturn> {
  @override
  OrderReturn build() {
    return EmptyModels.empty<OrderReturn>();
  }

  void setOrder(OrderReturn order) {
    state = order;
  }
}

final orderProvider = NotifierProvider<OrderNotifier, OrderReturn>(
  OrderNotifier.new,
);
