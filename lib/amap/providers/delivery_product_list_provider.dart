import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class DeliveryProductListNotifier
    extends ListNotifierAPI<AppModulesAmapSchemasAmapProductComplete> {
  Openapi get productListRepository => ref.watch(repositoryProvider);

  @override
  AsyncValue<List<AppModulesAmapSchemasAmapProductComplete>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<AppModulesAmapSchemasAmapProductComplete>>>
  loadProductList(
    List<AppModulesAmapSchemasAmapProductComplete> products,
  ) async {
    return state = AsyncValue.data(products);
  }

  // TODO: Require back changes, should take a single product and return the
  // created AppModulesAmapSchemasAmapProductComplete rather than a list of ids.
  //
  // Until then the endpoint answers 204 with no body, so there is nothing to
  // insert into the local list — going through `add` made every call report
  // failure on a request that had in fact succeeded. Callers reload the
  // delivery's products with [loadProductList] once this returns.
  Future<bool> addProduct(
    DeliveryProductsUpdate product,
    String deliveryId,
  ) async {
    return handleState((_) async {
      final response = await productListRepository
          .amapDeliveriesDeliveryIdProductsPost(
            deliveryId: deliveryId,
            body: product,
          );
      if (!response.isSuccessful) {
        throw response.error ?? Exception('Failed to add product');
      }
      return true;
    }, 'Cannot add while loading');
  }

  Future<bool> deleteProduct(
    AppModulesAmapSchemasAmapProductComplete product,
    String deliveryId,
  ) async {
    return await delete(
      () async => productListRepository.amapDeliveriesDeliveryIdProductsDelete(
        deliveryId: deliveryId,
        body: DeliveryProductsUpdate(productsIds: [product.id]),
      ),
      (product) => product.id,
      product.id,
    );
  }
}

final deliveryProductListProvider =
    NotifierProvider<
      DeliveryProductListNotifier,
      AsyncValue<List<AppModulesAmapSchemasAmapProductComplete>>
    >(() => DeliveryProductListNotifier());
