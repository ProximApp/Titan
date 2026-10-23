import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../shared/app_scaffold.dart';

/// The amap admin gate group.
const amapAdminGroupId = '70db65ee-d533-4f6b-9ffa-a4d70a17b7ef';

/// The user every amap admin-shell test mounts with.
final CoreUser amapAdminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin_amap', id: amapAdminGroupId)],
);

/// Stubs everything the amap admin page loads on mount: the cash, delivery
/// and product lists, plus — with [withDeliveryOrders] — the per-delivery
/// orders its delivery cards auto-load (an un-stubbed call would read as a
/// null Future<Response> and kill the whole child-route mount with a type
/// error). The list defaults are const unmodifiable: DeliveryHandler sorts
/// a copy of the provider's list (ledger #12), and the honest fixture
/// guards that fix. Four admin files rebuilt this block by hand.
void stubAdminLoads(
  IntegrationScaffold scaffold, {
  List<AppModulesAmapSchemasAmapCashComplete> cashes = const [],
  List<AppModulesAmapSchemasAmapProductComplete> products = const [],
  List<DeliveryReturn> deliveries = const [],
  Map<String, List<OrderReturn>> ordersByDelivery = const {},
  bool withDeliveryOrders = false,
}) {
  when(() => scaffold.repository.amapUsersCashGet())
      .thenAnswer((_) async => chopperListResponse(cashes));
  when(() => scaffold.repository.amapDeliveriesGet())
      .thenAnswer((_) async => chopperListResponse(deliveries));
  when(() => scaffold.repository.amapProductsGet())
      .thenAnswer((_) async => chopperListResponse(products));
  if (withDeliveryOrders) {
    when(
      () => scaffold.repository.amapDeliveriesDeliveryIdOrdersGet(
        deliveryId: any(named: 'deliveryId'),
      ),
    ).thenAnswer(
      (inv) async => chopperListResponse(
        ordersByDelivery[inv.namedArguments[#deliveryId] as String] ??
            const <OrderReturn>[],
      ),
    );
  }
}
