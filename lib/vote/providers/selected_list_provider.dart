import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class SelectedListProvider extends Notifier<ListReturn> {
  @override
  ListReturn build() {
    return EmptyModels.empty<ListReturn>();
  }

  void changeSelection(ListReturn s) {
    state = s;
  }

  void clear() {
    state = EmptyModels.empty<ListReturn>();
  }
}

final selectedListProvider = NotifierProvider<SelectedListProvider, ListReturn>(
  SelectedListProvider.new,
);
