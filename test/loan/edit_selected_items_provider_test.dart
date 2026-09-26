import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/providers/edit_selected_items_provider.dart';
import 'package:titan/loan/providers/item_list_provider.dart';
import 'package:titan/loan/providers/loan_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

/// Stands in for the real [ItemListNotifier], whose build() fetches from the
/// repository, so the selection slots can be seeded deterministically.
class FakeItemListNotifier extends ItemListNotifier {
  FakeItemListNotifier(this.items);

  final List<Item> items;

  @override
  AsyncValue<List<Item>> build() => AsyncValue.data(items);
}

class FakeLoanerListNotifier extends UserLoanerListNotifier {
  @override
  AsyncValue<List<Loaner>> build() => const AsyncValue.data([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditSelectedListProvider', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late EditSelectedListProvider notifier;
    final items = [
      Item.empty().copyWith(id: 'i1', name: 'Tente'),
      Item.empty().copyWith(id: 'i2', name: 'Chaise'),
    ];

    setUp(() {
      mockRepository = MockRepository();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepository),
          itemListProvider.overrideWith(() => FakeItemListNotifier(items)),
          userLoanerListProvider.overrideWith(FakeLoanerListNotifier.new),
        ],
      );
      notifier = container.read(editSelectedListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('starts with one slot per item, all zero', () {
      container.read(editSelectedListProvider);

      expect(container.read(editSelectedListProvider), [0, 0]);
    });

    test('prefills quantities from the loan being edited', () async {
      await container
          .read(loanProvider.notifier)
          .setLoan(
            Loan.empty().copyWith(
              itemsQty: [
                ItemQuantity(
                  quantity: 3,
                  itemSimple: ItemSimple.empty().copyWith(id: 'i1'),
                ),
              ],
            ),
          );
      container.read(editSelectedListProvider);

      expect(container.read(editSelectedListProvider), [3, 0]);
    });

    test('toggle switches between zero and the given quantity', () async {
      // Seed the state directly for the pure toggle logic.
      notifier.state = [0, 0];

      await notifier.toggle(0, 5);
      expect(container.read(editSelectedListProvider), [5, 0]);

      await notifier.toggle(0, 5);
      expect(container.read(editSelectedListProvider), [0, 0]);
    });

    test('set replaces the quantity of one slot', () async {
      notifier.state = [0, 0];

      await notifier.set(1, 2);

      expect(container.read(editSelectedListProvider), [0, 2]);
    });

    test('clear zeroes every slot', () async {
      notifier.state = [1, 2, 3];

      notifier.clear();

      expect(container.read(editSelectedListProvider), [0, 0, 0]);
    });
  });

  group('LoanerIdProvider', () {
    test('defaults to empty when the loaner list is empty', () {
      final container = ProviderContainer(
        overrides: [
          userLoanerListProvider.overrideWith(FakeLoanerListNotifier.new),
        ],
      );

      expect(container.read(loanerIdProvider), '');

      container.dispose();
    });

    test('setId overrides the loaner id', () {
      final container = ProviderContainer(
        overrides: [
          userLoanerListProvider.overrideWith(FakeLoanerListNotifier.new),
        ],
      );

      container.read(loanerIdProvider.notifier).setId('loaner-9');

      expect(container.read(loanerIdProvider), 'loaner-9');

      container.dispose();
    });
  });
}
