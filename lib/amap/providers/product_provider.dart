import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/amap/class/product.dart';

class ProductNotifier extends Notifier<Product> {
  @override
  Product build() {
    return Product.empty();
  }

  void setProduct(Product product) {
    state = product;
  }
}

final productProvider = NotifierProvider<ProductNotifier, Product>(
  ProductNotifier.new,
);
