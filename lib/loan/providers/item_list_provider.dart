import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/loan/class/item.dart';
import 'package:titan/loan/repositories/item_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class ItemListNotifier extends ListNotifier<Item> {
  ItemRepository get itemRepository =>
      ref.watch(itemRepositoryProvider);

  @override
  AsyncValue<List<Item>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Item>>> loadItemList(String id) async {
    return await loadList(() async => itemRepository.getItemList(id));
  }

  Future<bool> addItem(Item item, String loanerId) async {
    return await add(
      (i) async => itemRepository.createItem(loanerId, i),
      item,
    );
  }

  Future<bool> updateItem(Item item, String loanerId) async {
    return await update(
      (i) async => itemRepository.updateItem(loanerId, i),
      (items, item) => items..[items.indexWhere((i) => i.id == item.id)] = item,
      item,
    );
  }

  Future<bool> deleteItem(Item item, String loanerId) async {
    return await delete(
      (id) async => itemRepository.deleteItem(loanerId, id),
      (items, item) => items..removeWhere((i) => i.id == item.id),
      item.id,
      item,
    );
  }

  Future<AsyncValue<List<Item>>> copy() async {
    return state.whenData((d) => d.sublist(0));
  }

  Future<AsyncValue<List<Item>>> filterItems(String query) async {
    return state.whenData(
      (items) => items
          .where(
            (item) => item.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList(),
    );
  }
}

final itemListProvider =
    NotifierProvider<ItemListNotifier, AsyncValue<List<Item>>>(
      ItemListNotifier.new,
    );
