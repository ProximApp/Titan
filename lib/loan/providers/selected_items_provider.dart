import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/item_list_provider.dart';

class SelectedListProvider extends Notifier<List<int>> {
  @override
  List<int> build() {
    final itemsList = ref.watch(itemListProvider);
    final List<Item> items = [];
    itemsList.maybeWhen(data: (list) => items.addAll(list), orElse: () {});
    return List.generate(items.length, (index) => 0);
  }

  Future<List<int>> toggle(int i, int quantity) async {
    var copy = state.toList();
    copy[i] = copy[i] == 0 ? quantity : 0;
    state = copy;
    return state;
  }

  Future<List<int>> set(int i, int quantity) async {
    var copy = state.toList();
    copy[i] = quantity;
    state = copy;
    return state;
  }

  void initWithLoan(List<Item> items, Loan loan) {
    var copy = state.toList();
    final itemIds = items.map((i) => i.id).toList();
    for (var itemQty in loan.itemsQty) {
      if (itemIds.contains(itemQty.itemSimple.id)) {
        copy[itemIds.indexOf(itemQty.itemSimple.id)] = itemQty.quantity;
      }
    }
    state = copy;
  }

  void clear() {
    state = List.generate(state.length, (index) => 0);
  }
}

final selectedListProvider = NotifierProvider<SelectedListProvider, List<int>>(
  SelectedListProvider.new,
);
