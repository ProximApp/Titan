import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/loan/class/loaner.dart';
import 'package:titan/loan/repositories/loaner_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class LoanerListNotifier extends ListNotifier<Loaner> {
  LoanerRepository get loanerRepository => ref.watch(loanerRepositoryProvider);

  @override
  AsyncValue<List<Loaner>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Loaner>>> loadLoanerList() async {
    return await loadList(loanerRepository.getLoanerList);
  }

  Future<bool> addLoaner(Loaner loaner) async {
    return await add(loanerRepository.createLoaner, loaner);
  }

  Future<bool> updateLoaner(Loaner loaner) async {
    return await update(
      loanerRepository.updateLoaner,
      (loaners, loaner) =>
          loaners..[loaners.indexWhere((i) => i.id == loaner.id)] = loaner,
      loaner,
    );
  }

  Future<bool> deleteLoaner(Loaner loaner) async {
    return await delete(
      loanerRepository.deleteLoaner,
      (loans, loan) => loans..removeWhere((i) => i.id == loan.id),
      loaner.id,
      loaner,
    );
  }
}

final loanerListProvider =
    NotifierProvider<LoanerListNotifier, AsyncValue<List<Loaner>>>(
      LoanerListNotifier.new,
    );
