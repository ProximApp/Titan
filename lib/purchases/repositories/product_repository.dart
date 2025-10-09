import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/purchases/class/product.dart';
import 'package:titan/tools/repository/repository.dart';

class ProductRepository extends Repository {
  @override
  // ignore: overridden_fields
  final ext = "cdr/sellers/";

  Future<List<Product>> getProductList(String sellerId) async {
    return List<Product>.from(
      (await getList(
        suffix: "$sellerId/products/",
      )).map((x) => Product.fromJson(x)),
    );
  }
}

final productRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return ProductRepository()..setToken(token);
});
