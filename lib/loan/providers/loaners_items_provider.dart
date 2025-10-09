import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/loan/class/item.dart';
import 'package:titan/loan/class/loaner.dart';
import 'package:titan/tools/providers/map_provider.dart';

class LoanersItemsNotifier extends MapNotifier<Loaner, Item> {}

final loanersItemsProvider =
    NotifierProvider<
      LoanersItemsNotifier,
      Map<Loaner, AsyncValue<List<Item>>?>
    >(() => LoanersItemsNotifier());
