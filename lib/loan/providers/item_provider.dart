import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class ItemNotifier extends Notifier<Item> {
  @override
  Item build() {
    return EmptyModels.empty<Item>();
  }

  void setItem(Item item) {
    state = item;
  }
}

final itemProvider = NotifierProvider<ItemNotifier, Item>(ItemNotifier.new);
