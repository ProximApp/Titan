import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/product_id_provider.dart';
import 'package:titan/purchases/providers/purchase_provider.dart';
import 'package:titan/purchases/providers/seller_provider.dart';
import 'package:titan/purchases/providers/tag_provider.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  group('SellerNotifier', () {
    test('defaults to empty and can be set', () {
      final notifier = container.read(sellerProvider.notifier);

      expect(container.read(sellerProvider).id, '');

      final seller = SellerComplete.empty().copyWith(id: 'seller-1');
      notifier.setSeller(seller);

      expect(container.read(sellerProvider).id, 'seller-1');
    });
  });

  group('TagNotifier', () {
    test('defaults to empty and can be set', () {
      final notifier = container.read(tagProvider.notifier);

      expect(container.read(tagProvider), '');

      notifier.setTag('bracelet');

      expect(container.read(tagProvider), 'bracelet');
    });
  });

  group('ProductIdNotifier', () {
    test('starts loading and can be set', () {
      final notifier = container.read(productIdProvider.notifier);

      expect(container.read(productIdProvider).isLoading, true);

      notifier.setProductId('product-1');

      expect(container.read(productIdProvider).value, 'product-1');
    });
  });

  group('PurchaseNotifier', () {
    test('starts loading and can be set', () {
      final notifier = container.read(purchaseProvider.notifier);

      expect(container.read(purchaseProvider).isLoading, true);

      final purchase = PurchaseReturn.empty().copyWith(quantity: 2);
      notifier.setPurchase(purchase);

      expect(container.read(purchaseProvider).value!.quantity, 2);
    });
  });
}
