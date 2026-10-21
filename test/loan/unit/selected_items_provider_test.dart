import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/item_list_provider.dart';
import 'package:titan/loan/providers/selected_items_provider.dart';

void main() {
  List<Item> items() => [
    Item.empty().copyWith(id: '1'),
    Item.empty().copyWith(id: '2'),
    Item.empty().copyWith(id: '3'),
  ];

  ProviderContainer buildContainer({List<Item>? initial}) {
    final container = ProviderContainer(
      overrides: [
        itemListProvider.overrideWith(
          () => _StubItemListNotifier(AsyncValue.data(initial ?? items())),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SelectedListProvider', () {
    test('should initialize with false values', () {
      final container = buildContainer();
      final provider = container.read(selectedListProvider.notifier);
      expect(provider.state, [0, 0, 0]);
    });

    test('should initialize with no values when the items failed to load', () {
      final container = ProviderContainer(
        overrides: [
          itemListProvider.overrideWith(
            () => _StubItemListNotifier(
              AsyncValue.error('boom', StackTrace.empty),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = container.read(selectedListProvider.notifier);
      expect(provider.state, isEmpty);
    });

    test('should toggle value at index', () async {
      final container = buildContainer();
      final provider = container.read(selectedListProvider.notifier);

      expect(await provider.toggle(1, 5), [0, 5, 0]);
      expect(await provider.toggle(1, 5), [0, 0, 0]);
    });

    test('should set value at index', () async {
      final container = buildContainer();
      final provider = container.read(selectedListProvider.notifier);

      expect(await provider.set(2, 3), [0, 0, 3]);
      expect(await provider.set(2, 0), [0, 0, 0]);
    });

    test('should initialize with loan items selected', () {
      final container = buildContainer();
      final provider = container.read(selectedListProvider.notifier);
      final loan = Loan.empty().copyWith(
        itemsQty: [
          ItemQuantity.empty().copyWith(
            quantity: 2,
            itemSimple: ItemSimple.empty().copyWith(id: '1'),
          ),
          ItemQuantity.empty().copyWith(
            quantity: 4,
            itemSimple: ItemSimple.empty().copyWith(id: '3'),
          ),
        ],
      );

      provider.initWithLoan(items(), loan);
      expect(provider.state, [2, 0, 4]);
    });

    test('should clear all selected values', () async {
      final container = buildContainer();
      final provider = container.read(selectedListProvider.notifier);

      await provider.toggle(1, 5);
      provider.clear();
      expect(provider.state, [0, 0, 0]);
    });
  });
}

class _StubItemListNotifier extends ItemListNotifier {
  _StubItemListNotifier(this._initial);

  final AsyncValue<List<Item>> _initial;

  @override
  AsyncValue<List<Item>> build() => _initial;
}
