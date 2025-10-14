import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/amap/providers/category_list_provider.dart';
import 'package:titan/amap/providers/product_list_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';

class MockProductListRepository extends Mock implements Openapi {}

void main() {
  group('categoryListProvider', () {
    final products = [
      AppModulesAmapSchemasAmapProductComplete(
        id: '1',
        name: 'Product A',
        category: 'Category A',
        price: 10,
      ),
      AppModulesAmapSchemasAmapProductComplete(
        id: '2',
        name: 'Product B',
        category: 'Category B',
        price: 20,
      ),
      AppModulesAmapSchemasAmapProductComplete(
        id: '3',
        name: 'Product C',
        category: 'Category A',
        price: 30,
      ),
    ];

    test('returns a list of categories when productListProvider is loaded', () {
      final container = ProviderContainer(
        overrides: [productListProvider.overrideWith(ProductListNotifier.new)],
      );

      final result = container.read(categoryListProvider);

      expect(result, ['Category A', 'Category B']);
    });

    test('returns an empty list when productListProvider is loading', () {
      final container = ProviderContainer(
        overrides: [productListProvider.overrideWith(ProductListNotifier.new)],
      );

      final result = container.read(categoryListProvider);

      expect(result, []);
    });

    test('returns an empty list when productListProvider has an error', () {
      final container = ProviderContainer(
        overrides: [productListProvider.overrideWith(ProductListNotifier.new)],
      );

      final result = container.read(categoryListProvider);

      expect(result, []);
    });

    test(
      'returns a list of categories when productListProvider is refreshed',
      () async {
        final mockProductListRepository = MockProductListRepository();
        final productListNotifier = ProductListNotifier();
        when(() => mockProductListRepository.amapProductsGet()).thenAnswer(
          (_) async => chopper.Response(http.Response('[]', 200), products),
        );
        final container = ProviderContainer(
          overrides: [
            productListProvider.overrideWith(ProductListNotifier.new),
          ],
        );

        await productListNotifier.loadProductList();
        final result = container.read(categoryListProvider);

        expect(result, ['Category A', 'Category B']);
      },
    );
  });
}
