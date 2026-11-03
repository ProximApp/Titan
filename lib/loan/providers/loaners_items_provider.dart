import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/tools/providers/map_provider.dart';

class LoanersItemsNotifier extends MapNotifier<Loaner, Item> {
  @override
  Map<Loaner, AsyncValue<List<Item>>?> build() {
    final loaners = ref.watch(loanerList);
    return {for (final loaner in loaners) loaner: null};
  }
}

final loanersItemsProvider =
    NotifierProvider<
      LoanersItemsNotifier,
      Map<Loaner, AsyncValue<List<Item>>?>
    >(() => LoanersItemsNotifier());
