import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/amap/providers/user_order_list_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

class _UserOrderListNotifier extends UserOrderListNotifier {
  @override
  AsyncValue<List<OrderReturn>> build() => const AsyncValue.loading();
}

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        userOrderListProvider.overrideWith(_UserOrderListNotifier.new),
      ],
    );
    addTearDown(container.dispose);
  });

  ProductQuantity productQuantity(int price, int quantity) =>
      ProductQuantity.empty().copyWith(
        quantity: quantity,
        product: AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
          price: price,
        ),
      );

  group('UserOrderListNotifier', () {
    test('loadDeliveryOrderList resolves the orders of a delivery', () async {
      when(() => repo.amapDeliveriesDeliveryIdOrdersGet(deliveryId: 'd-1'))
          .thenAnswer((_) async => repo.okList<OrderReturn>());
      final notifier = container.read(userOrderListProvider.notifier);
      final state = await notifier.loadDeliveryOrderList('d-1');
      expect(state.value, isEmpty);
    });

    test('setProducts success persists and stores the new basket', () async {
      final notifier = container.read(userOrderListProvider.notifier);
      final order = OrderReturn.empty().copyWith(orderId: 'o-1');
      notifier.state = AsyncValue.data([order]);
      when(
        () => repo.amapOrdersOrderIdPatch(
          orderId: 'o-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final products = [productQuantity(350, 3)];
      final ok = await notifier.setProducts(0, products, 'd-1', 'u-1');
      expect(ok, isTrue);
      expect(notifier.state.value!.single.productsdetail, products);
    });

    test('setProducts failure restores the previous basket', () async {
      final notifier = container.read(userOrderListProvider.notifier);
      final order = OrderReturn.empty().copyWith(
        orderId: 'o-1',
        productsdetail: [productQuantity(100, 1)],
      );
      notifier.state = AsyncValue.data([order]);
      // The patch endpoint never throws on a non-2xx status, so the only way
      // into the catch arm is a transport level error.
      when(
        () => repo.amapOrdersOrderIdPatch(
          orderId: 'o-1',
          body: any(named: 'body'),
        ),
      ).thenThrow(StateError('connection reset'));

      final ok = await notifier.setProducts(
        0,
        [productQuantity(350, 3)],
        'd-1',
        'u-1',
      );
      expect(ok, isFalse);
      expect(notifier.state.value!.single.productsdetail.single.quantity, 1);
    });

    test('setProducts refuses to run while loading or in error', () async {
      final notifier = container.read(userOrderListProvider.notifier);

      notifier.state = const AsyncValue.loading();
      expect(await notifier.setProducts(0, [], 'd-1', 'u-1'), isFalse);

      notifier.state = AsyncValue.error('boom', StackTrace.empty);
      expect(await notifier.setProducts(0, [], 'd-1', 'u-1'), isFalse);
    });

    test('getPrice sums the basket lines', () async {
      final notifier = container.read(userOrderListProvider.notifier);
      final order = OrderReturn.empty().copyWith(
        orderId: 'o-1',
        productsdetail: [productQuantity(350, 3), productQuantity(200, 1)],
      );
      notifier.state = AsyncValue.data([order]);
      expect(await notifier.getPrice(0), 350 * 3 + 200);
    });

    test('getPrice returns zero while loading or in error', () async {
      final notifier = container.read(userOrderListProvider.notifier);

      notifier.state = const AsyncValue.loading();
      expect(await notifier.getPrice(0), 0);

      notifier.state = AsyncValue.error('boom', StackTrace.empty);
      expect(await notifier.getPrice(0), 0);
    });

    test('copy duplicates the loaded orders', () async {
      final notifier = container.read(userOrderListProvider.notifier);
      final order = OrderReturn.empty().copyWith(orderId: 'o-1');
      notifier.state = AsyncValue.data([order]);
      final copied = await notifier.copy();
      expect(copied.value!.single.orderId, 'o-1');
    });

    test('addOrder and updateOrder and deleteOrder round-trip', () async {
      final notifier = container.read(userOrderListProvider.notifier);
      final order = OrderReturn.empty().copyWith(orderId: 'o-1');
      notifier.state = AsyncValue.data([order]);

      when(() => repo.amapOrdersPost(body: any(named: 'body')))
          .thenAnswer((_) async => repo.ok(order));
      expect(await notifier.addOrder(OrderBase.empty()), isTrue);
      expect(notifier.state.value!.length, 2);

      when(
        () => repo.amapOrdersOrderIdPatch(
          orderId: 'o-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());
      expect(await notifier.updateOrder(order.copyWith(amount: 999)), isTrue);
      expect(
        notifier.state.value!.firstWhere((o) => o.orderId == 'o-1').amount,
        999,
      );

      when(() => repo.amapOrdersOrderIdDelete(orderId: 'o-1'))
          .thenAnswer((_) async => repo.okVoid());
      expect(await notifier.deleteOrder(order), isTrue);
      expect(notifier.state.value!.where((o) => o.orderId == 'o-1'), isEmpty);
    });
  });
}
