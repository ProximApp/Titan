import 'package:flutter_test/flutter_test.dart';
import 'package:titan/amap/notification_service.dart';
import 'package:titan/amap/providers/delivery_list_provider.dart';
import 'package:titan/amap/providers/delivery_order_list_provider.dart';
import 'package:titan/amap/providers/user_amount_provider.dart';

/// The notification routing table: every notification topic names the page
/// that must refresh and the providers it has to reload. Reading the table
/// is the only way to reach its entries — nothing else in the module
/// iterates it.
void main() {
  test('routes each topic to its page and providers', () {
    expect(
      amapProviders.keys,
      containsAll(<String>['cash', 'delivery', 'orders']),
    );
    expect(amapProviders.length, 3);

    // cash: the main page, refreshing the balance.
    expect(amapProviders['cash']!.item1, '/amap');
    expect(amapProviders['cash']!.item2, [userAmountProvider]);

    // delivery: the main page, refreshing the delivery list.
    expect(amapProviders['delivery']!.item1, '/amap');
    expect(amapProviders['delivery']!.item2, [deliveryListProvider]);

    // orders: the admin page, refreshing the per-delivery order lists.
    expect(amapProviders['orders']!.item1, '/amap/admin');
    expect(amapProviders['orders']!.item2, [adminDeliveryOrderListProvider]);
  });
}
