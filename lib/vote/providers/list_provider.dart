import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class ListNotifier extends Notifier<ListReturn> {
  @override
  ListReturn build() {
    return EmptyModels.empty<ListReturn>();
  }

  void setId(ListReturn p) {
    state = p;
  }
}

final listProvider = NotifierProvider<ListNotifier, ListReturn>(
  ListNotifier.new,
);
