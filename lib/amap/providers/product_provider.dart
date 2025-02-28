import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class ProductNotifier
    extends Notifier<AppModulesAmapSchemasAmapProductComplete> {
  @override
  AppModulesAmapSchemasAmapProductComplete build() {
    return EmptyModels.empty<AppModulesAmapSchemasAmapProductComplete>();
  }

  void setProduct(AppModulesAmapSchemasAmapProductComplete product) {
    state = product;
  }
}

final productProvider =
    NotifierProvider<ProductNotifier, AppModulesAmapSchemasAmapProductComplete>(
      ProductNotifier.new,
    );
