import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/amap/class/product.dart';
import 'package:titan/amap/providers/product_list_provider.dart';

class SortedByCategoryProvider extends Notifier<Map<String, List<Product>>> {
  @override
  Map<String, List<Product>> build() {
    final products = ref.watch(productListProvider);
    final sortedByCategoryProducts = <String, List<Product>>{};
    products.maybeWhen(
      data: (products) {
        for (var product in products) {
          if (sortedByCategoryProducts.containsKey(product.category)) {
            sortedByCategoryProducts[product.category]!.add(product);
          } else {
            sortedByCategoryProducts[product.category] = [product];
          }
        }
      },
      orElse: () {},
    );
    return sortedByCategoryProducts;
  }
}

final sortedByCategoryProductsProvider =
    NotifierProvider<SortedByCategoryProvider, Map<String, List<Product>>>(
      () => SortedByCategoryProvider(),
    );
