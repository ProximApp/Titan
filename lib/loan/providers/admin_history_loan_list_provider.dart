import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/history_loaner_loan_list_provider.dart';
import 'package:titan/loan/providers/loaner_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/tools/builders/empty_models.dart';
import 'package:titan/tools/providers/map_provider.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class AdminHistoryLoanListNotifier extends MapNotifier<Loaner, Loan> {
  @override
  Map<Loaner, AsyncValue<List<Loan>>?> build() {
    tokenExpireWrapperAuth(ref, () async {
      final loaners = ref.watch(loanerList);
      final loaner = ref.watch(loanerProvider);
      final loanListNotifier = ref.watch(
        historyLoanerLoanListProvider.notifier,
      );
      loadTList(loaners);
      if (loaner.id == EmptyModels.empty<Loaner>()) return state;
      loanListNotifier.loadLoan(loaner.id).then((value) {
        setTData(loaner, value);
      });
    });
    return state;
  }
}

final adminHistoryLoanListProvider =
    NotifierProvider<
      AdminHistoryLoanListNotifier,
      Map<Loaner, AsyncValue<List<Loan>>?>
    >(() => AdminHistoryLoanListNotifier());
