import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/providers/delivery_product_list_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

class MockDeliveryProductListRepository extends Mock implements Openapi {}

void main() {
  group('DeliveryProductListNotifier', () {
    late MockDeliveryProductListRepository productListRepository;
    late ProviderContainer container;
    late DeliveryProductListNotifier notifier;

    final products = [
      AppModulesAmapSchemasAmapProductComplete(
        id: '1',
        name: 'Product 1',
        category: 'Category 1',
        price: 10,
      ),
      AppModulesAmapSchemasAmapProductComplete(
        id: '2',
        name: 'Product 2',
        category: 'Category 2',
        price: 20,
      ),
    ];

    final product = AppModulesAmapSchemasAmapProductComplete(
      id: '3',
      name: 'New Product',
      category: 'Category 3',
      price: 30,
    );

    final productToAdd = DeliveryProductsUpdate(productsIds: [product.id]);

    setUp(() async {
      productListRepository = MockDeliveryProductListRepository();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(productListRepository),
        ],
      );
      notifier = container.read(deliveryProductListProvider.notifier);
      await Future(() {});
    });

    tearDown(() => container.dispose());

    test(
      'loadProductList should return AsyncValue with provided list of products',
      () async {
        final result = await notifier.loadProductList(products);

        expect(result, AsyncValue.data(products));
      },
    );

    test('addProduct returns true when the endpoint answers 204', () async {
      // The endpoint answers 204, so nothing comes back to insert in the local
      // list: callers reload the delivery products themselves.
      when(
        () => productListRepository.amapDeliveriesDeliveryIdProductsPost(
          deliveryId: any(named: 'deliveryId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(http.Response('', 204), null),
      );

      notifier.state = AsyncValue.data(products.sublist(0));
      final result = await notifier.addProduct(productToAdd, 'deliveryId');

      expect(result, true);
    });

    test('addProduct returns false when the endpoint fails', () async {
      when(
        () => productListRepository.amapDeliveriesDeliveryIdProductsPost(
          deliveryId: any(named: 'deliveryId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<void>(
          http.Response('', 403),
          null,
          error: Exception('Failed to add product'),
        ),
      );

      notifier.state = AsyncValue.data(products.sublist(0));
      final result = await notifier.addProduct(productToAdd, 'deliveryId');

      expect(result, false);
    });

    test(
      'deleteProduct should remove product from list and return true',
      () async {
        notifier.state = AsyncValue.data([...products, product]);

        when(
          () => productListRepository.amapDeliveriesDeliveryIdProductsDelete(
            deliveryId: any(named: 'deliveryId'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => chopper.Response(http.Response('[]', 200), true),
        );

        final result = await notifier.deleteProduct(product, 'deliveryId');

        expect(result, true);
        expect(
          notifier.state.when(
            data: (data) => data,
            error: (e, s) => [],
            loading: () => [],
          ),
          products,
        );
      },
    );
  });
}
