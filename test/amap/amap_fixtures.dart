import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../shared/app_scaffold.dart';

/// A member's cash balance — the balance card and the amount picker both
/// read it. `userId` is the user every amap shell test signs in as.
AppModulesAmapSchemasAmapCashComplete cash(int balance) =>
    AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
      balance: balance,
      userId: 'user-1',
    );

/// A delivery with [productCount] products, in the orderable state the
/// admin delivery cards render their Order button for.
DeliveryReturn orderableDelivery(String id, int productCount) =>
    DeliveryReturn.empty().copyWith(
      id: id,
      name: 'Delivery $id',
      deliveryDate: DateTime(2100, 12, 31),
      status: DeliveryStatusType.orderable,
      products: List.generate(
        productCount,
        (i) => AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
          id: 'p-$i',
          name: 'Product $i',
        ),
      ),
    );

/// An order booked against [deliveryId] for [amount] euros.
OrderReturn order(String orderId, String deliveryId, int amount) =>
    OrderReturn.empty().copyWith(
      orderId: orderId,
      deliveryId: deliveryId,
      amount: amount,
      deliveryDate: DateTime(2100, 12, 31),
      orderingDate: DateTime(2100),
    );

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
/// null `Future<Response>` and kill the whole child-route mount with a type
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
