import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

class SelectedListProvider extends Notifier<ListReturn> {
  @override
  ListReturn build() {
    return ListReturn.fromJson({});
  }

  void changeSelection(ListReturn s) {
    state = s;
  }

  void clear() {
    state = ListReturn.fromJson({});
  }
}

final selectedListProvider =
    NotifierProvider<SelectedListProvider, ListReturn>(SelectedListProvider.new);
