import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/last_used_store_id_provider.dart';
import 'package:titan/mypayment/providers/my_stores_provider.dart';
import 'package:titan/mypayment/providers/selected_interval_provider.dart';
import 'package:titan/mypayment/providers/selected_store_history.dart';
import 'package:titan/mypayment/providers/store_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class FakeOpenapi extends Fake implements Openapi {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(FakeOpenapi())],
    );
  });

  tearDown(() => container.dispose());

  group('SellerHistoryNotifier', () {
    test('stays loading until a real store is selected', () {
      container.read(sellerHistoryProvider);

      expect(container.read(sellerHistoryProvider).isLoading, true);
    });

    test('initializes its watched providers without network access', () {
      // Watched inside build(): selectedStoreProvider (myStoresProvider) and
      // selectedIntervalProvider. With an empty store none of the endpoints
      // fire, so nothing but the repository container is needed.
      container.read(myStoresProvider);
      container.read(selectedIntervalProvider);

      expect(container.read(sellerHistoryProvider).isLoading, true);
    });
  });

  group('StoreProvider', () {
    test('defaults to empty and can be updated', () {
      final notifier = container.read(storeProvider.notifier);
      expect(container.read(storeProvider).id, '');

      final store = UserStore.empty().copyWith(id: 'store-1');
      notifier.updateStore(store);
      expect(container.read(storeProvider).id, 'store-1');
    });
  });

  group('LastUsedStoreIdNotifier', () {
    test('loads the saved store id from preferences', () async {
      SharedPreferences.setMockInitialValues({'last_used_store': 'store-42'});
      final notifier = container.read(lastUsedStoreIdProvider.notifier);

      await notifier.loadLastUsedStoreId();

      expect(container.read(lastUsedStoreIdProvider), 'store-42');
    });

    test('keeps the default when nothing is saved', () async {
      final notifier = container.read(lastUsedStoreIdProvider.notifier);

      await notifier.loadLastUsedStoreId();

      expect(container.read(lastUsedStoreIdProvider), '');
    });

    test('saves the store id to preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = container.read(lastUsedStoreIdProvider.notifier);

      await notifier.saveLastUsedStoreIdToSharedPreferences('store-7');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_used_store'), 'store-7');
    });
  });
}
