import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/amap/class/product.dart';
import 'package:titan/amap/repositories/product_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ProductListNotifier extends ListNotifier<Product> {
  ProductListRepository get productListRepository =>
      ref.watch(productListRepositoryProvider);

  @override
  AsyncValue<List<Product>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Product>>> loadProductList() async {
    return await loadList(productListRepository.getProductList);
  }

  Future<bool> addProduct(Product product) async {
    return await add(productListRepository.createProduct, product);
  }

  Future<bool> updateProduct(Product product) async {
    return await update(
      productListRepository.updateProduct,
      (products, product) =>
          products..[products.indexWhere((p) => p.id == product.id)] = product,
      product,
    );
  }

  Future<bool> deleteProduct(Product product) async {
    return await delete(
      productListRepository.deleteProduct,
      (products, product) => products..removeWhere((i) => i.id == product.id),
      product.id,
      product,
    );
  }
}

final productListProvider =
    NotifierProvider<ProductListNotifier, AsyncValue<List<Product>>>(
      ProductListNotifier.new,
    );
